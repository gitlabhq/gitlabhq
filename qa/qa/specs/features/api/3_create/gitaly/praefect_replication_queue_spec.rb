# frozen_string_literal: true

require 'parallel'

module QA
  RSpec.describe 'Create' do
    context 'Gitaly Cluster replication queue', :orchestrated, :gitaly_cluster, :skip_live_env do
      let(:praefect_manager) { Service::PraefectManager.new }
      let(:project) do
        Resource::Project.fabricate! do |project|
          project.name = "gitaly_cluster"
          project.initialize_with_readme = true
        end
      end

      after do
        praefect_manager.start_praefect
        praefect_manager.wait_for_reliable_connection
        praefect_manager.clear_replication_queue
      end

      it 'allows replication of different repository after interruption', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/975' do
        # We want to fill the replication queue with 10 `in_progress` jobs,
        # while a lock has been acquired, which is when the problem occurred
        # as reported in https://gitlab.com/gitlab-org/gitaly/-/issues/2801
        #
        # We'll do this by creating 10 branches and pushing them all at once,
        # and then stop Praefect when a lock is acquired, set all the jobs
        # to `in_progress`, and create a job lock for each one.
        queue_size_target = 10

        Git::Repository.perform do |repository|
          repository.uri = project.repository_http_location.uri
          repository.use_default_credentials
          repository.clone
          repository.configure_identity('GitLab QA', 'root@gitlab.com')
          1.upto(queue_size_target) do |i|
            repository.checkout("branch#{i}", new_branch: true)
            repository.commit_file("file#{i}", SecureRandom.random_bytes(10000000), "Add file#{i}")
          end
          repository.push_all_branches
        end

        count = 0
        while count < 1
          count = praefect_manager.replication_queue_lock_count
          QA::Runtime::Logger.debug("Lock count: #{count}")
        end

        praefect_manager.stop_praefect
        praefect_manager.create_stalled_replication_queue

        praefect_manager.start_praefect
        praefect_manager.wait_for_reliable_connection

        # Create a new project, push to it, and check that replication occurs
        project_push = Resource::Repository::ProjectPush.fabricate! do |push|
          push.project_name = "gitaly_cluster"
        end

        expect(praefect_manager.replicated?(project_push.project.id)).to be true
      end
    end
  end
end
