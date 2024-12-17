# frozen_string_literal: true

require 'parallel'

module QA
  RSpec.describe 'Systems', product_group: :gitaly do
    describe 'Gitaly Cluster replication queue', :orchestrated, :gitaly_cluster, :skip_live_env do
      let(:praefect_manager) { Service::PraefectManager.new }
      let(:project) do
        Resource::Project.fabricate! do |project|
          project.name = "gitaly_cluster"
          project.initialize_with_readme = true
        end
      end

      before do
        praefect_manager.start_all_nodes
      end

      after do
        praefect_manager.start_all_nodes
        praefect_manager.clear_replication_queue
      end

      it 'allows replication of different repository after interruption',
        quarantine: {
          issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/489130',
          type: :investigating
        },
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347829' do
        # We want to fill the replication queue with 10 `in_progress` jobs,
        # while a lock has been acquired, which is when the problem occurred
        # as reported in https://gitlab.com/gitlab-org/gitaly/-/issues/2801
        #
        # We'll do this by creating 10 branches and pushing them all at once,
        # and then stop Praefect when a lock is acquired, set all the jobs
        # to `in_progress`, and create a job lock for each one.
        queue_size_target = 10

        # During normal operations we avoid create a replication event
        # https://gitlab.com/groups/gitlab-org/-/epics/7741
        praefect_manager.stop_node(praefect_manager.secondary_node)
        Git::Repository.perform do |repository|
          repository.uri = project.repository_http_location.uri
          repository.use_default_credentials
          repository.clone
          repository.use_default_identity
          1.upto(queue_size_target) do |i|
            repository.checkout("branch#{i}", new_branch: true)
            repository.commit_file("file#{i}", SecureRandom.random_bytes(10000000), "Add file#{i}")
          end
          repository.push_all_branches
        end
        praefect_manager.start_node(praefect_manager.secondary_node)

        Support::Retrier.retry_until(max_duration: 60) do
          count = praefect_manager.replication_queue_lock_count
          QA::Runtime::Logger.debug("Lock count: #{count}")
          count >= 1
        end

        praefect_manager.stop_praefect
        praefect_manager.create_stalled_replication_queue

        praefect_manager.start_praefect

        # Create a new project, and check that replication occurs
        new_project = Resource::Project.fabricate! do |project|
          project.initialize_with_readme = true
        end

        expect(praefect_manager.replicated?(new_project.id, new_project.name)).to be true
      end
    end
  end
end
