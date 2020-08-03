# frozen_string_literal: true

module QA
  module Service
    class PraefectManager
      include Service::Shellout

      attr_accessor :gitlab

      def initialize
        @gitlab = 'gitlab-gitaly-ha'
        @praefect = 'praefect'
        @postgres = 'postgres'
        @primary_node = 'gitaly1'
        @secondary_node = 'gitaly2'
        @tertiary_node = 'gitaly3'
        @virtual_storage = 'default'
      end

      # Executes the praefect `dataloss` command.
      #
      # @return [Boolean] whether dataloss has occurred
      def dataloss?
        wait_until_shell_command_matches(dataloss_command, /Outdated repositories/)
      end

      def replicated?(project_id)
        replicas = wait_until_shell_command(%(docker exec gitlab-gitaly-ha bash -c 'gitlab-rake "gitlab:praefect:replicas[#{project_id}]"')) do |line|
          QA::Runtime::Logger.debug(line.chomp)
          # The output of the rake task looks something like this:
          #
          # Project name                    | gitaly1 (primary)                        | gitaly2                                  | gitaly3
          # ----------------------------------------------------------------------------------------------------------------------------------------------------------------
          # gitaly_cluster-3aff1f2bd14e6c98 | 23c4422629234d62b62adacafd0a33a8364e8619 | 23c4422629234d62b62adacafd0a33a8364e8619 | 23c4422629234d62b62adacafd0a33a8364e8619
          #
          break line if line.start_with?("gitaly_cluster")
        end

        # We want to know if the checksums are identical
        replicas.split('|').map(&:strip)[1..3].uniq.one?
      end

      def start_primary_node
        start_node(@primary_node)
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
        QA::Runtime::Logger.info("Stopping node #{@primary_node} to trigger failover")
        stop_node(@primary_node)
      end

      def clear_replication_queue
        QA::Runtime::Logger.info("Clearing the replication queue")
        shell sql_to_docker_exec_cmd(
          <<~SQL
            delete from replication_queue_job_lock;
            delete from replication_queue_lock;
            delete from replication_queue;
          SQL
        )
      end

      def create_stalled_replication_queue
        QA::Runtime::Logger.info("Setting jobs in replication queue to `in_progress` and acquiring locks")
        shell sql_to_docker_exec_cmd(
          <<~SQL
            update replication_queue set state = 'in_progress';
            insert into replication_queue_job_lock (job_id, lock_id, triggered_at)
              select id, rq.lock_id, created_at from replication_queue rq
                left join replication_queue_job_lock rqjl on rq.id = rqjl.job_id
                where state = 'in_progress' and rqjl.job_id is null;
            update replication_queue_lock set acquired = 't';
          SQL
        )
      end

      # Reconciles the previous primary node with the current one
      # I.e., it brings the previous primary node up-to-date
      def reconcile_nodes
        reconcile_node_with_node(@primary_node, current_primary_node)
      end

      def reconcile_node_with_node(target, reference)
        QA::Runtime::Logger.info("Reconcile #{target} with #{reference} on #{@virtual_storage}")
        wait_until_shell_command_matches(
          "docker exec #{@praefect} bash -c '/opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml reconcile -virtual #{@virtual_storage} -target #{target} -reference #{reference} -f'",
          /FINISHED: \d+ repos were checked for consistency/,
          sleep_interval: 5,
          retry_on_exception: true
        )
      end

      def replication_queue_lock_count
        result = []
        shell sql_to_docker_exec_cmd("select count(*) from replication_queue_lock where acquired = 't';") do |line|
          result << line
        end
        # The result looks like:
        #   count
        #   -----
        #       1
        result[2].to_i
      end

      # Makes the original primary (gitaly1) the primary again by
      # stopping the other nodes, waiting for gitaly1 to be made the
      # primary again, and then it starts the other nodes and enables
      # writes
      def reset_primary_to_original
        QA::Runtime::Logger.info("Checking primary node...")

        return if @primary_node == current_primary_node

        QA::Runtime::Logger.info("Reset primary node to #{@primary_node}")
        start_node(@primary_node)
        stop_node(@secondary_node)
        stop_node(@tertiary_node)

        wait_for_new_primary_node(@primary_node)

        start_node(@secondary_node)
        start_node(@tertiary_node)

        wait_for_health_check_all_nodes
        wait_for_reliable_connection
      end

      def reset_cluster
        QA::Runtime::Logger.info('Reset Gitaly Cluster by starting all nodes and enabling writes')
        start_node(@praefect)
        start_node(@primary_node)
        start_node(@secondary_node)
        start_node(@tertiary_node)
        wait_for_health_check_all_nodes
      end

      def verify_storage_move(source_storage, destination_storage)
        return if QA::Runtime::Env.dot_com?

        repo_path = verify_storage_move_from_gitaly(source_storage[:name])

        destination_storage[:type] == :praefect ? verify_storage_move_to_praefect(repo_path, destination_storage[:name]) : verify_storage_move_to_gitaly(repo_path, destination_storage[:name])
      end

      def wait_for_praefect
        QA::Runtime::Logger.info('Wait until Praefect starts and is listening')
        wait_until_shell_command_matches(
          "docker exec #{@praefect} bash -c 'cat /var/log/gitlab/praefect/current'",
          /listening at tcp address/
        )

        # Praefect can fail to start if unable to dial one of the gitaly nodes
        # See https://gitlab.com/gitlab-org/gitaly/-/issues/2847
        # We tail the logs to allow us to confirm if that is the problem if tests fail

        shell "docker exec #{@praefect} bash -c 'tail /var/log/gitlab/praefect/current'" do |line|
          QA::Runtime::Logger.debug(line.chomp)
        end
      end

      def wait_for_new_primary_node(node)
        QA::Runtime::Logger.info("Wait until #{node} is the primary node")
        with_praefect_log do |log|
          break true if log['msg'] == 'primary node changed' && log['newPrimary'] == node
        end
      end

      def wait_for_new_primary
        QA::Runtime::Logger.info("Wait until a new primary node is selected")
        with_praefect_log do |log|
          break true if log['msg'] == 'primary node changed'
        end
      end

      def wait_for_sql_ping
        wait_until_shell_command_matches(
          "docker exec #{@praefect} bash -c '/opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml sql-ping'",
          /praefect sql-ping: OK/
        )
      end

      def wait_for_no_praefect_storage_error
        # If a healthcheck error was the last message to be logged, we'll keep seeing that message even if it's no longer a problem
        # That is, there's no message shown in the Praefect logs when the healthcheck succeeds
        # To work around that we perform the gitaly check rake task, wait a few seconds, and then we confirm that no healthcheck errors appear

        QA::Runtime::Logger.info("Checking that Praefect does not report healthcheck errors with its gitaly nodes")

        Support::Waiter.wait_until(max_duration: 120) do
          wait_for_gitaly_check

          sleep 5

          shell "docker exec #{@praefect} bash -c 'tail -n 1 /var/log/gitlab/praefect/current'" do |line|
            QA::Runtime::Logger.debug(line.chomp)
            log = JSON.parse(line)

            break true if log['msg'] != 'error when pinging healthcheck'
          rescue JSON::ParserError
            # Ignore lines that can't be parsed as JSON
          end
        end
      end

      def wait_for_storage_nodes
        wait_for_no_praefect_storage_error

        Support::Waiter.repeat_until(max_attempts: 3) do
          nodes_confirmed = {
            @primary_node => false,
            @secondary_node => false,
            @tertiary_node => false
          }

          wait_until_shell_command("docker exec #{@praefect} bash -c '/opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dial-nodes'") do |line|
            QA::Runtime::Logger.debug(line.chomp)

            nodes_confirmed.each_key do |node|
              nodes_confirmed[node] = true if line =~ /SUCCESS: confirmed Gitaly storage "#{node}" in virtual storages \[#{@virtual_storage}\] is served/
            end

            nodes_confirmed.values.all?
          end
        end
      end

      def wait_for_health_check_current_primary_node
        wait_for_health_check(current_primary_node)
      end

      def wait_for_health_check_all_nodes
        wait_for_health_check(@primary_node)
        wait_for_health_check(@secondary_node)
        wait_for_health_check(@tertiary_node)
      end

      def wait_for_health_check(node)
        QA::Runtime::Logger.info("Waiting for health check on #{node}")
        wait_until_shell_command("docker exec #{node} bash -c 'cat /var/log/gitlab/gitaly/current'") do |line|
          QA::Runtime::Logger.debug(line.chomp)
          log = JSON.parse(line)

          log['grpc.request.fullMethod'] == '/grpc.health.v1.Health/Check' && log['grpc.code'] == 'OK'
        rescue JSON::ParserError
          # Ignore lines that can't be parsed as JSON
        end
      end

      def wait_for_gitaly_check
        Support::Waiter.repeat_until(max_attempts: 3) do
          storage_ok = false
          check_finished = false

          wait_until_shell_command("docker exec #{@gitlab} bash -c 'gitlab-rake gitlab:gitaly:check'") do |line|
            QA::Runtime::Logger.debug(line.chomp)

            storage_ok = true if line =~ /Gitaly: ... #{@virtual_storage} ... OK/
            check_finished = true if line =~ /Checking Gitaly ... Finished/

            storage_ok && check_finished
          end
        end
      end

      def wait_for_gitlab_shell_check
        wait_until_shell_command_matches(
          "docker exec #{@gitlab} bash -c 'gitlab-rake gitlab:gitlab_shell:check'",
          /Checking GitLab Shell ... Finished/
        )
      end

      def wait_for_reliable_connection
        QA::Runtime::Logger.info('Wait until GitLab and Praefect can communicate reliably')
        wait_for_praefect
        wait_for_sql_ping
        wait_for_storage_nodes
        wait_for_gitlab_shell_check
      end

      def wait_for_replication(project_id)
        Support::Waiter.wait_until(sleep_interval: 1) { replicated?(project_id) }
      end

      private

      def current_primary_node
        shell dataloss_command do |line|
          QA::Runtime::Logger.debug(line.chomp)

          match = line.match(/Primary: (.*)/)
          break match[1] if match
        end
      end

      def dataloss_command
        "docker exec #{@praefect} bash -c '/opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dataloss'"
      end

      def sql_to_docker_exec_cmd(sql)
        Service::Shellout.sql_to_docker_exec_cmd(sql, 'postgres', 'SQL_PASSWORD', 'praefect_production', 'postgres.test', @postgres)
      end

      def verify_storage_move_from_gitaly(storage)
        wait_until_shell_command("docker exec #{@gitlab} bash -c 'tail -n 50 /var/log/gitlab/gitaly/current'") do |line|
          log = JSON.parse(line)

          break log['grpc.request.repoPath'] if log['grpc.method'] == 'RenameRepository' && log['grpc.request.repoStorage'] == storage && !log['grpc.request.repoPath'].include?('wiki')
        rescue JSON::ParserError
          # Ignore lines that can't be parsed as JSON
        end
      end

      def verify_storage_move_to_praefect(repo_path, virtual_storage)
        wait_until_shell_command("docker exec #{@gitlab} bash -c 'tail -n 50 /var/log/gitlab/praefect/current'") do |line|
          log = JSON.parse(line)

          log['grpc.method'] == 'ReplicateRepository' && log['virtual_storage'] == virtual_storage && log['relative_path'] == repo_path
        rescue JSON::ParserError
          # Ignore lines that can't be parsed as JSON
        end
      end

      def verify_storage_move_to_gitaly(repo_path, storage)
        wait_until_shell_command("docker exec #{@gitlab} bash -c 'tail -n 50 /var/log/gitlab/gitaly/current'") do |line|
          log = JSON.parse(line)

          log['grpc.method'] == 'ReplicateRepository' && log['grpc.request.repoStorage'] == storage && log['grpc.request.repoPath'] == repo_path
        rescue JSON::ParserError
          # Ignore lines that can't be parsed as JSON
        end
      end

      def with_praefect_log
        wait_until_shell_command("docker exec #{@praefect} bash -c 'tail -n 1 /var/log/gitlab/praefect/current'") do |line|
          QA::Runtime::Logger.debug(line.chomp)
          yield JSON.parse(line)
        end
      end
    end
  end
end
