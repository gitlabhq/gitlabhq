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

      def praefect_sql_ping_healthy?
        cmd = "docker exec #{@praefect} bash -c '/opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml sql-ping'"
        wait_until_shell_command(cmd) do |line|
          QA::Runtime::Logger.debug(line.chomp)
          break line.include?('praefect sql-ping: OK')
        end
      end

      def wait_for_dial_nodes_successful
        Support::Waiter.repeat_until(max_attempts: 3, max_duration: 120, sleep_interval: 1) do
          nodes_confirmed = {
            @primary_node => false,
            @secondary_node => false,
            @tertiary_node => false
          }

          nodes_confirmed.each_key do |node|
            nodes_confirmed[node] = true if praefect_dial_nodes_status?(node)
          end

          nodes_confirmed.values.all?
        end
      end

      def praefect_dial_nodes_status?(node, expect_healthy = true)
        cmd = "docker exec #{@praefect} bash -c '/opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dial-nodes -timeout 1s'"
        if expect_healthy
          wait_until_shell_command_matches(cmd, /SUCCESS: confirmed Gitaly storage "#{node}" in virtual storages \[#{@virtual_storage}\] is served/)
        else
          wait_until_shell_command(cmd, raise_on_failure: false) do |line|
            QA::Runtime::Logger.debug(line.chomp)
            break true if line.include?('the following nodes are not healthy') && line.include?(node)
          end
        end
      end

      def praefect_dataloss_information(project_id)
        dataloss_info = []
        cmd = "docker exec #{@praefect} praefect -config /var/opt/gitlab/praefect/config.toml dataloss --partially-unavailable=true"
        shell(cmd) { |line| dataloss_info << line.strip }

        # Expected will have a record for each repository in the storage, in the following format
        #   @hashed/bc/52/bc52dd634277c4a34a2d6210994a9a5e2ab6d33bb4a3a8963410e00ca6c15a02.git:
        #     Primary: gitaly1
        #       In-Sync Storages:
        #         gitaly1, assigned host
        #         gitaly3, assigned host
        #       Outdated Storages:
        #         gitaly2 is behind by 1 change or less, assigned host
        #
        # Alternatively, if all repositories are in sync, a concise message is returned
        #   Virtual storage: default
        #     All repositories are fully available on all assigned storages!

        # extract the relevant project under test info if it is identified
        start_index = dataloss_info.index { |line| line.include?("#{Digest::SHA256.hexdigest(project_id.to_s)}.git") }
        unless start_index.nil?
          dataloss_info = dataloss_info[start_index, 7]
        end

        dataloss_info&.each { |info| QA::Runtime::Logger.debug(info) }
        dataloss_info
      end

      def wait_for_project_synced_across_all_storages(project_id)
        Support::Retrier.retry_until(max_duration: 60) do
          praefect_dataloss_information(project_id).include?('All repositories are fully available on all assigned storages!')
        end
      end

      def accept_dataloss_for_project(project_id, authoritative_storage)
        repository_hash = "#{Digest::SHA256.hexdigest(project_id.to_s)}"
        repository = "@hashed/#{repository_hash[0, 2]}/#{repository_hash[2, 2]}/#{repository_hash}.git"

        cmd = %{
          docker exec #{@praefect} \
          praefect \
            -config /var/opt/gitlab/praefect/config.toml \
            accept-dataloss \
            --virtual-storage=default \
            --repository=#{repository} \
            --authoritative-storage=#{authoritative_storage}
        }
        shell(cmd)
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

      def wait_for_replication_to_node(project_id, node)
        Support::Waiter.wait_until(sleep_interval: 1) do
          result = []
          shell sql_to_docker_exec_cmd(%{
            select * from replication_queue
            where state = 'ready'
              and job ->> 'change' = 'update'
              and job ->> 'target_node_storage' = '#{node}'
              and job ->> 'relative_path' = '#{Digest::SHA256.hexdigest(project_id.to_s)}.git';
          }) do |line|
            result << line.strip
            QA::Runtime::Logger.debug(line.strip)
          end
          # The result should look like this when all items are replicated
          #    id | state | created_at | updated_at | attempt | lock_id | job | meta
          #   ----+-------+------------+------------+---------+---------+-----+------
          #   (0 rows)
          result[2] == '(0 rows)'
        end
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

      def list_untracked_repositories
        untracked_repositories = []
        shell "docker exec #{@praefect} bash -c 'gitlab-ctl praefect list-untracked-repositories'" do |line|
          # Results look like this
          #   The following repositories were found on disk, but missing from the tracking database:
          #   {"relative_path":"@hashed/aa/bb.git","storage":"gitaly1","virtual_storage":"default"}
          #   {"relative_path":"@hashed/bb/cc.git","storage":"gitaly3","virtual_storage":"default"}

          QA::Runtime::Logger.debug(line.chomp)
          untracked_repositories.append(JSON.parse(line))
        rescue JSON::ParserError
          # Ignore lines that can't be parsed as JSON
        end

        QA::Runtime::Logger.debug("list_untracked_repositories --- #{untracked_repositories}")
        untracked_repositories
      end

      def track_repository_in_praefect(relative_path, storage, virtual_storage)
        cmd = "gitlab-ctl praefect track-repository --repository-relative-path #{relative_path} --authoritative-storage #{storage} --virtual-storage-name #{virtual_storage}"
        shell "docker exec #{@praefect} bash -c '#{cmd}'"
      end

      def remove_tracked_praefect_repository(relative_path, virtual_storage)
        cmd = "gitlab-ctl praefect remove-repository --repository-relative-path #{relative_path} --virtual-storage-name #{virtual_storage} --apply"
        shell "docker exec #{@praefect} bash -c '#{cmd}'"
      end

      # set_replication_factor assigns or unassigns random storage nodes as necessary to reach the desired replication factor for a repository
      def set_replication_factor(relative_path, virtual_storage, factor)
        cmd = "/opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml set-replication-factor -repository #{relative_path} -virtual-storage #{virtual_storage} -replication-factor #{factor}"
        shell "docker exec #{@praefect} bash -c '#{cmd}'"
      end

      # get_replication_storages retrieves a list of currently assigned storages for a repository
      def get_replication_storages(relative_path, virtual_storage)
        storage_repositories = []
        query = "SELECT storage FROM repository_assignments WHERE relative_path='#{relative_path}' AND virtual_storage='#{virtual_storage}';"
        shell(sql_to_docker_exec_cmd(query)) { |line| storage_repositories << line.strip }
        # Returned data from query will be in format
        #    storage
        #    --------
        #    gitaly1
        #    gitaly3
        #    gitaly2
        #   (3 rows)
        #

        # remove 2 header rows and last 2 rows from query response (including blank line)
        storage_repositories[2..-3]
      end

      def modify_repo_access_time(node, repo_path, update_time)
        repo = "/var/opt/gitlab/git-data/repositories/#{repo_path}"
        shell(%{
          docker exec --user git #{node} bash -c 'find #{repo} -exec touch -d "#{update_time}" {} \\;'
        })
      end

      def add_repo_to_disk(node, repo_path)
        cmd = "GIT_DIR=. git init --initial-branch=main /var/opt/gitlab/git-data/repositories/#{repo_path}"
        shell "docker exec --user git #{node} bash -c '#{cmd}'"
        modify_repo_access_time(node, repo_path, "24 hours ago")
      end

      def remove_repo_from_disk(repo_path)
        cmd = "rm -rf /var/opt/gitlab/git-data/repositories/#{repo_path}"
        shell "docker exec #{@primary_node} bash -c '#{cmd}'"
        shell "docker exec #{@secondary_node} bash -c '#{cmd}'"
        shell "docker exec #{@tertiary_node} bash -c '#{cmd}'"
      end

      def remove_repository_from_praefect_database(relative_path)
        shell sql_to_docker_exec_cmd("delete from repositories where relative_path = '#{relative_path}';")
        shell sql_to_docker_exec_cmd("delete from storage_repositories where relative_path = '#{relative_path}';")
      end

      def praefect_database_tracks_repo?(relative_path)
        storage_repositories = []
        shell sql_to_docker_exec_cmd("SELECT count(*) FROM storage_repositories where relative_path='#{relative_path}';") do |line|
          storage_repositories << line
        end
        QA::Runtime::Logger.debug("storage_repositories count is ---#{storage_repositories}")

        repositories = []
        shell sql_to_docker_exec_cmd("SELECT count(*) FROM repositories where relative_path='#{relative_path}';") do |line|
          repositories << line
        end
        QA::Runtime::Logger.debug("repositories count is ---#{repositories}")

        (storage_repositories[2].to_i >= 1) && (repositories[2].to_i >= 1)
      end

      def repository_replicated_to_disk?(node, relative_path)
        Support::Waiter.wait_until(max_duration: 300, sleep_interval: 1, raise_on_failure: false) do
          result = []
          shell sql_to_docker_exec_cmd("SELECT count(*) FROM storage_repositories where relative_path='#{relative_path}';") do |line|
            result << line
          end
          QA::Runtime::Logger.debug("result is ---#{result}")
          result[2].to_i == 3
        end

        repository_exists_on_node_disk?(node, relative_path)
      end

      def repository_exists_on_node_disk?(node, relative_path)
        # If the dir does not exist it has a non zero exit code leading to a error being raised
        # Instead we echo a test line if the dir does not exist, which has a zero exit code, with no output
        bash_command = "test -d /var/opt/gitlab/git-data/repositories/#{relative_path} || echo -n 'DIR_DOES_NOT_EXIST'"
        result = []
        shell "docker exec #{node} bash -c '#{bash_command}'" do |line|
          result << line
        end
        QA::Runtime::Logger.debug("result is ---#{result}")
        result.exclude?("DIR_DOES_NOT_EXIST")
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
