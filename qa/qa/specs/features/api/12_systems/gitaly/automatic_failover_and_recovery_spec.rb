# frozen_string_literal: true

module QA
  RSpec.describe 'Systems', product_group: :gitaly do
    context 'with Gitaly automatic failover and recovery', :orchestrated, :gitaly_cluster do
      # Variables shared between contexts. They're used and shared between
      # contexts so they can't be `let` variables.
      praefect_manager = Service::PraefectManager.new
      project = nil

      let(:intial_commit_message) { 'Initial commit' }
      let(:first_added_commit_message) { 'first_added_commit_message to primary gitaly node' }
      let(:second_added_commit_message) { 'second_added_commit_message to failover node' }

      before(:context) do
        praefect_manager.start_all_nodes

        project = Resource::Project.fabricate! do |project|
          project.name = "gitaly_cluster"
          project.initialize_with_readme = true
        end
        # We need to ensure that the the project is replicated to all nodes before proceeding with this test
        praefect_manager.wait_for_replication(project.id)
      end

      it 'automatically fails over',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347830' do
        # stop other nodes, so we can control which node the commit is sent to
        praefect_manager.stop_node(praefect_manager.secondary_node)
        praefect_manager.stop_node(praefect_manager.tertiary_node)

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.commit_message = first_added_commit_message
          push.new_branch = false
          push.file_content = 'This file created on gitaly1 while gitaly2/gitaly3 not running'
        end

        praefect_manager.start_all_nodes
        praefect_manager.wait_for_replication(project.id)

        # Stop the primary node to trigger failover, and then wait
        # for Gitaly to be ready for writes again
        praefect_manager.stop_node(praefect_manager.primary_node)
        praefect_manager.wait_for_health_check_failure(praefect_manager.primary_node)

        create(:commit, project: project, commit_message: second_added_commit_message, actions: [{
          action: 'create',
          file_path: "file-#{SecureRandom.hex(8)}",
          content: 'This is created on gitaly2/gitaly3 while gitaly1 is unavailable'
        }])

        # Confirm that we have access to the repo after failover,
        # including the commit we just added
        expect(project.commits.map { |commit| commit[:message].chomp })
          .to include(intial_commit_message)
          .and include(first_added_commit_message)
          .and include(second_added_commit_message)
      end

      context 'when recovering from dataloss after failover' do
        it 'automatically reconciles',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347831' do
          # Start the old primary node again
          praefect_manager.start_node(praefect_manager.primary_node)
          praefect_manager.wait_for_gitaly_health_check(praefect_manager.primary_node)

          # Confirm automatic reconciliation
          expect(praefect_manager.replicated?(project.id)).to be true

          # Confirm that all commits are available after reconciliation
          expect(project.commits.map { |commit| commit[:message].chomp })
            .to include(intial_commit_message)
            .and include(first_added_commit_message)
            .and include(second_added_commit_message)

          # Restore the original primary node
          praefect_manager.start_all_nodes

          # Check that all commits are still available even though the primary
          # node was offline when one was made
          expect(project.commits.map { |commit| commit[:message].chomp })
            .to include(intial_commit_message)
            .and include(first_added_commit_message)
            .and include(second_added_commit_message)
        end
      end
    end
  end
end
