# frozen_string_literal: true

module QA
  module Service
    class PraefectManager
      include Service::Shellout

      def initialize
        @gitlab = 'gitlab-gitaly-ha'
        @praefect = 'praefect'
        @postgres = 'postgres'
        @primary_node = 'gitaly1'
        @secondary_node = 'gitaly2'
        @tertiary_node = 'gitaly3'
        @virtual_storage = 'default'
      end

      def enable_writes
        shell "docker exec #{@praefect} bash -c '/opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml enable-writes -virtual-storage #{@virtual_storage}'"
      end

      def replicated?(project_id)
        shell %(docker exec gitlab-gitaly-ha bash -c 'gitlab-rake "gitlab:praefect:replicas[#{project_id}]"') do |line|
          # The output of the rake task looks something like this:
          #
          # Project name                    | gitaly1 (primary)                        | gitaly2                                  | gitaly3
          # ----------------------------------------------------------------------------------------------------------------------------------------------------------------
          # gitaly_cluster-3aff1f2bd14e6c98 | 23c4422629234d62b62adacafd0a33a8364e8619 | 23c4422629234d62b62adacafd0a33a8364e8619 | 23c4422629234d62b62adacafd0a33a8364e8619
          #
          # We want to confirm that the checksums are identical
          break line.split('|').map(&:strip)[1..3].uniq.one? if line.start_with?("gitaly_cluster")
        end
      end

      def start_praefect
        start_node(@praefect)
      end

      def stop_praefect
        stop_node(@praefect)
      end

      def start_node(name)
        shell "docker start #{name}"
      end

      def stop_node(name)
        shell "docker stop #{name}"
      end

      def trigger_failover_by_stopping_primary_node
        stop_node(@primary_node)
      end

      def clear_replication_queue
        QA::Runtime::Logger.debug("Clearing the replication queue")
        shell <<~CMD
          docker exec --env PGPASSWORD=SQL_PASSWORD #{@postgres} \
            bash -c "psql -U postgres -d praefect_production -h postgres.test \
            -c \\"delete from replication_queue_job_lock; delete from replication_queue_lock; delete from replication_queue;\\""
        CMD
      end

      def create_stalled_replication_queue
        QA::Runtime::Logger.debug("Setting jobs in replication queue to `in_progress` and acquiring locks")
        shell <<~CMD
          docker exec --env PGPASSWORD=SQL_PASSWORD #{@postgres} \
            bash -c "psql -U postgres -d praefect_production -h postgres.test \
            -c \\"update replication_queue set state = 'in_progress';
                  insert into replication_queue_job_lock (job_id, lock_id, triggered_at)
                    select id, rq.lock_id, created_at from replication_queue rq
                      left join replication_queue_job_lock rqjl on rq.id = rqjl.job_id
                      where state = 'in_progress' and rqjl.job_id is null;
                  update replication_queue_lock set acquired = 't';\\""
        CMD
      end

      def replication_queue_lock_count
        result = []
        cmd = <<~CMD
          docker exec --env PGPASSWORD=SQL_PASSWORD #{@postgres} \
            bash -c "psql -U postgres -d praefect_production -h postgres.test \
            -c \\"select count(*) from replication_queue_lock where acquired = 't';\\""
        CMD
        shell cmd do |line|
          result << line
        end
        # The result looks like:
        #   count
        #   -----
        #       1
        result[2].to_i
      end

      def reset_cluster
        start_node(@praefect)
        start_node(@primary_node)
        start_node(@secondary_node)
        start_node(@tertiary_node)
        enable_writes
      end

      def wait_for_praefect
        wait_until_shell_command_matches(
          "docker exec #{@praefect} bash -c 'cat /var/log/gitlab/praefect/current'",
          /listening at tcp address/
        )
      end

      def wait_for_sql_ping
        wait_until_shell_command_matches(
          "docker exec #{@praefect} bash -c '/opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml sql-ping'",
          /praefect sql-ping: OK/
        )
      end

      def wait_for_storage_nodes
        nodes_confirmed = {
          @primary_node => false,
          @secondary_node => false,
          @tertiary_node => false
        }

        wait_until_shell_command("docker exec #{@praefect} bash -c '/opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dial-nodes'") do |line|
          QA::Runtime::Logger.info(line.chomp)

          nodes_confirmed.each_key do |node|
            nodes_confirmed[node] = true if line =~ /SUCCESS: confirmed Gitaly storage "#{node}" in virtual storages \[#{@virtual_storage}\] is served/
          end

          nodes_confirmed.values.all?
        end
      end

      def wait_for_gitaly_check
        storage_ok = false
        check_finished = false

        wait_until_shell_command("docker exec #{@gitlab} bash -c 'gitlab-rake gitlab:gitaly:check'") do |line|
          QA::Runtime::Logger.info(line.chomp)

          storage_ok = true if line =~ /Gitaly: ... #{@virtual_storage} ... OK/
          check_finished = true if line =~ /Checking Gitaly ... Finished/

          storage_ok && check_finished
        end
      end

      def wait_for_gitlab_shell_check
        wait_until_shell_command_matches(
          "docker exec #{@gitlab} bash -c 'gitlab-rake gitlab:gitlab_shell:check'",
          /Checking GitLab Shell ... Finished/
        )
      end

      def wait_for_reliable_connection
        wait_for_praefect
        wait_for_sql_ping
        wait_for_storage_nodes
        wait_for_gitaly_check
        wait_for_gitlab_shell_check
      end

      private

      def wait_until_shell_command(cmd)
        Support::Waiter.wait_until do
          shell cmd do |line|
            break true if yield line
          end
        end
      end

      def wait_until_shell_command_matches(cmd, regex)
        wait_until_shell_command(cmd) do |line|
          QA::Runtime::Logger.info(line.chomp)

          line =~ regex
        end
      end
    end
  end
end
