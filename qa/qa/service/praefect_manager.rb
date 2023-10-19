# frozen_string_literal: true

require 'digest'

module QA
  module Service
    class PraefectManager
      include Service::Shellout

      attr_accessor :gitlab

      attr_reader :primary_node, :secondary_node, :tertiary_node, :postgres

      PrometheusQueryError = Class.new(StandardError)

      def initialize
        @gitlab = 'gitlab-gitaly-cluster'
        @praefect = 'praefect'
        @postgres = 'postgres'
        @primary_node = 'gitaly1'
        @secondary_node = 'gitaly2'
        @tertiary_node = 'gitaly3'
        @virtual_storage = 'default'
      end

      def gitaly_nodes
        [primary_node, secondary_node, tertiary_node]
      end

      # Executes the praefect `dataloss` command.
      #
      # @return [Boolean] whether dataloss has occurred
      def dataloss?
        wait_until_shell_command_matches(dataloss_command, /Outdated repositories/)
      end

      def replicated?(project_id, project_name_prefix = 'gitaly_cluster')
        Support::Retrier.retry_until(raise_on_failure: false) do
          replicas = wait_until_shell_command(%(docker exec #{@gitlab} bash -c 'gitlab-rake "gitlab:praefect:replicas[#{project_id}]"')) do |line|
            QA::Runtime::Logger.debug(line.chomp)
            # The output of the rake task looks something like this:
            #
            # Project name                    | gitaly1 (primary)                        | gitaly2                                  | gitaly3
            # ----------------------------------------------------------------------------------------------------------------------------------------------------------------
            # gitaly_cluster-3aff1f2bd14e6c98 | 23c4422629234d62b62adacafd0a33a8364e8619 | 23c4422629234d62b62adacafd0a33a8364e8619 | 23c4422629234d62b62adacafd0a33a8364e8619
            #
            break line if line.start_with?(project_name_prefix)
            break nil if line.include?('Something went wrong when getting replicas')
          end
          next false unless replicas

          # We want to know if the checksums are identical
          replicas&.split('|')&.map(&:strip)&.slice(1..3)&.uniq&.one?
        end
      end

      def start_praefect
        start_node(@praefect)
        QA::Runtime::Logger.info("Waiting for health check on praefect")
        Support::Waiter.wait_until(max_duration: 120, sleep_interval: 1, raise_on_failure: true) do
          wait_until_shell_command("docker exec #{@praefect} gitlab-ctl status praefect") do |line|
            break true if line.include?('run: praefect: ')

            QA::Runtime::Logger.debug(line.chomp)
          end
        end
      end

      def stop_praefect
        stop_node(@praefect)
      end

      def start_node(name)
        state = node_state(name)
        return if state == "running"

        if state == "paused"
          shell "docker unpause #{name}"
        end

        if state == "stopped"
          shell "docker start #{name}"
        end

        wait_until_shell_command_matches(
          "docker inspect -f {{.State.Running}} #{name}",
          /true/,
          sleep_interval: 1,
          max_duration: 180,
          retry_on_exception: true
        )
      end

      def stop_node(name)
        return if node_state(name) == 'paused'

        shell "docker pause #{name}"

        wait_until_node_is_removed_from_healthy_storages(name) if gitaly_nodes.include?(name)
      end

      def node_state(name)
        state = "stopped"
        wait_until_shell_command("docker inspect -f {{.State.Status}} #{name}", stream_progress: false) do |line|
          QA::Runtime::Logger.debug(line)
          break state = "running" if line.include?("running")
          break state = "paused" if line.include?("paused")
        end
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

      def query_read_distribution
        cmd = "docker exec #{@gitlab} bash -c 'curl -s http://localhost:9090/api/v1/query?query=gitaly_praefect_read_distribution'"
        output = shell(cmd, stream_progress: false) do |line|
          QA::Runtime::Logger.debug(line)
          break line
        end
        result = JSON.parse(output)

        raise PrometheusQueryError, "Unable to query read distribution metrics" unless result['status'] == 'success'

        raise PrometheusQueryError, "No read distribution metrics found" if result['data']['result'].empty?

        result['data']['result'].map { |result| { node: result['metric']['storage'], value: result['value'][1].to_i } }
      end

      def replication_queue_incomplete_count
        result = []
        shell sql_to_docker_exec_cmd("select count(*) from replication_queue where state = 'ready' or state = 'in_progress';") do |line|
          result << line
        end
        # The result looks like:
        #   count
        #   -----
        #       1
        result[2].to_i
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

      def start_all_nodes
        start_postgres
        gitaly_nodes.each { |node| start_node(node) }
        start_praefect

        wait_for_health_check_all_nodes
      end

      def start_postgres
        start_node(@postgres)

        Support::Waiter.repeat_until(max_attempts: 60, sleep_interval: 1) do
          shell(sql_to_docker_exec_cmd("SELECT 1 as healthy_database"), fail_on_exception: false) do |line|
            break true if line.include?("healthy_database")
          end
        end
      end

      def verify_storage_move(source_storage, destination_storage, repo_type: :project)
        return if Specs::Helpers::ContextSelector.dot_com?

        repo_path = verify_storage_move_from_gitaly(source_storage[:name], repo_type: repo_type)

        destination_storage[:type] == :praefect ? verify_storage_move_to_praefect(repo_path, destination_storage[:name]) : verify_storage_move_to_gitaly(repo_path, destination_storage[:name])
      end

      def wait_for_health_check_all_nodes
        gitaly_nodes.each { |node| wait_for_gitaly_health_check(node) }
      end

      def wait_for_gitaly_health_check(node)
        QA::Runtime::Logger.info("Waiting for health check on #{node}")
        Support::Waiter.wait_until(max_duration: 120, sleep_interval: 1, raise_on_failure: true) do
          wait_until_shell_command("docker exec #{node} gitlab-ctl status gitaly") do |line|
            break true if line.include?('run: gitaly: ')

            QA::Runtime::Logger.debug(line.chomp)
          end
        end
        wait_until_node_is_marked_as_healthy_storage(node)
      end

      def wait_for_health_check_failure(node)
        QA::Runtime::Logger.info("Waiting for health check failure on #{node}")
        wait_until_node_is_removed_from_healthy_storages(node)
      end

      def wait_until_node_is_removed_from_healthy_storages(node)
        Support::Waiter.wait_until(max_duration: 120, sleep_interval: 1, raise_on_failure: true) do
          result = []
          shell sql_to_docker_exec_cmd("SELECT count(*) FROM healthy_storages WHERE storage = '#{node}';") do |line|
            result << line
          end
          result[2].to_i == 0
        end
      end

      def wait_until_node_is_marked_as_healthy_storage(node)
        Support::Waiter.wait_until(max_duration: 120, sleep_interval: 1, raise_on_failure: true) do
          result = []
          shell sql_to_docker_exec_cmd("SELECT count(*) FROM healthy_storages WHERE storage = '#{node}';") do |line|
            result << line
          end
          result[2].to_i == 1
        end
      end

      # Waits until there is an increase in the number of reads for
      # any node compared to the number of reads provided. If a node
      # has no pre-read data, consider it to have had zero reads.
      def wait_for_read_count_change(pre_read_data)
        diff_found = false
        Support::Waiter.wait_until(sleep_interval: 1, max_duration: 60) do
          query_read_distribution.each_with_index do |data, index|
            diff_found = true if data[:value] > value_for_node(pre_read_data, data[:node])
          end
          diff_found
        end
      end

      def value_for_node(data, node)
        data.find(-> { { value: 0 } }) { |item| item[:node] == node }[:value]
      end

      def wait_for_replication(project_id)
        Support::Waiter.wait_until(sleep_interval: 1) { replication_queue_incomplete_count == 0 && replicated?(project_id) }
      end

      def replication_pending?
        result = []
        shell sql_to_docker_exec_cmd(
          <<~SQL
                  select job from replication_queue
                  where state = 'ready'
                    and job ->> 'change' = 'update'
                    and job ->> 'target_node_storage' = '#{@primary_node}';
          SQL
        ) do |line|
          result << line
        end

        # The result looks like:
        #
        #  job
        #  -----------
        #   {"change": "update", "params": null, "relative_path": "@hashed/4b/22/4b227777d4dd1fc61c6f884f48641d02b4d121d3fd328cb08b5531fcacdabf8a.git", "virtual_storage": "default", "source_node_storage": "gitaly3", "target_node_storage": "gitaly1"}
        #  (1 row)
        #  <blank row>
        #
        # Therefore when replication is pending there is at least 1 row of data plus 4 rows of metadata/layout

        result.size >= 5
      end

      def modify_repo_access_time(node, repo_path, update_time)
        repo = "/var/opt/gitlab/git-data/repositories/#{repo_path}"
        shell(%(
          docker exec --user git #{node} bash -c 'find #{repo} -exec touch -d "#{update_time}" {} \\;'
        ))
      end

      private

      def dataloss_command
        "docker exec #{@praefect} bash -c '/opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dataloss'"
      end

      def sql_to_docker_exec_cmd(sql)
        Service::Shellout.sql_to_docker_exec_cmd(sql, 'postgres', 'SQL_PASSWORD', 'praefect_production', 'postgres.test', @postgres)
      end

      def verify_storage_move_from_gitaly(storage, repo_type: :project)
        wait_until_shell_command("docker exec #{@gitlab} bash -c 'tail -n 50 /var/log/gitlab/gitaly/current'") do |line|
          log = JSON.parse(line)

          if (log['grpc.method'] == 'RenameRepository' || log['grpc.method'] == 'RemoveRepository') &&
              log['grpc.request.repoStorage'] == storage &&
              repo_type(log['grpc.request.repoPath']) == repo_type
            break log['grpc.request.repoPath']
          end
        rescue JSON::ParserError
          # Ignore lines that can't be parsed as JSON
        end
      end

      def verify_storage_move_to_praefect(repo_path, virtual_storage)
        wait_until_shell_command("docker exec #{@praefect} bash -c 'tail -n 50 /var/log/gitlab/praefect/current'") do |line|
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

      def repo_type(repo_path)
        return :snippet if repo_path.start_with?('@snippets')
        return :design if repo_path.end_with?('.design.git')

        if repo_path.end_with?('.wiki.git')
          return repo_path.start_with?('@groups') ? :group_wiki : :wiki
        end

        :project
      end
    end
  end
end
