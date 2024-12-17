# frozen_string_literal: true

module QA
  RSpec.describe 'Systems', product_group: :gitaly do
    describe 'Gitaly backend node recovery', :orchestrated, :gitaly_cluster, :skip_live_env do
      let(:praefect_manager) { Service::PraefectManager.new }
      let(:project) do
        Resource::Project.fabricate! do |project|
          project.name = "gitaly_cluster"
          project.initialize_with_readme = true
        end
      end

      before do
        # Reset the cluster in case previous tests left it in a bad state
        praefect_manager.start_all_nodes
      end

      after do
        # Leave the cluster in a suitable state for subsequent tests
        praefect_manager.start_all_nodes
      end

      it 'recovers from dataloss',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347832' do
        # Create a new project with a commit and wait for it to replicate
        praefect_manager.wait_for_replication(project.id)

        # Stop the primary node to trigger failover, and then wait
        # for Gitaly to be ready for writes again
        praefect_manager.stop_node(praefect_manager.primary_node)
        praefect_manager.wait_for_health_check_failure(praefect_manager.primary_node)

        # Push a commit to the new primary
        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.new_branch = false
          push.commit_message = 'pushed after failover'
          push.file_name = 'new_file'
          push.file_content = 'new file'
        end

        # Confirm that the commit is waiting to be replicated
        expect(praefect_manager).to be_replication_pending

        # Start the old primary node again
        praefect_manager.start_node(praefect_manager.primary_node)
        praefect_manager.wait_for_health_check_all_nodes

        # Wait for automatic replication
        praefect_manager.wait_for_replication(project.id)

        # Force switch to the old primary node
        # This ensures that the commit was replicated
        praefect_manager.stop_node(praefect_manager.secondary_node)
        praefect_manager.stop_node(praefect_manager.tertiary_node)

        # Confirm that both commits are available
        expect(project.commits.map { |commit| commit[:message].chomp })
          .to include("Initial commit").and include("pushed after failover")
      end
    end
  end
end
