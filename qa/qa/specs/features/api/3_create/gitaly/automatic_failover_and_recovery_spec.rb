# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    context 'Gitaly automatic failover and recovery', :orchestrated, :gitaly_cluster do
      # Variables shared between contexts. They're used and shared between
      # contexts so they can't be `let` variables.
      praefect_manager = Service::PraefectManager.new
      project = nil

      let(:intial_commit_message) { 'Initial commit' }
      let(:first_added_commit_message) { 'pushed to primary gitaly node' }
      let(:second_added_commit_message) { 'commit to failover node' }

      before(:context) do
        # Reset the cluster in case previous tests left it in a bad state
        praefect_manager.start_all_nodes

        project = Resource::Project.fabricate! do |project|
          project.name = "gitaly_cluster"
          project.initialize_with_readme = true
        end
      end

      after do
        praefect_manager.start_all_nodes
      end

      it 'automatically fails over', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347830' do
        # Create a new project with a commit and wait for it to replicate

        # make sure that our project is published to the 'primary' node
        praefect_manager.stop_secondary_node
        praefect_manager.stop_tertiary_node
        praefect_manager.wait_for_secondary_node_health_check_failure
        praefect_manager.wait_for_tertiary_node_health_check_failure

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.commit_message = first_added_commit_message
          push.new_branch = false
          push.file_content = "This should exist on all nodes"
        end

        praefect_manager.start_all_nodes
        praefect_manager.wait_for_replication(project.id)

        # Stop the primary node to trigger failover, and then wait
        # for Gitaly to be ready for writes again
        praefect_manager.stop_primary_node
        praefect_manager.wait_for_primary_node_health_check_failure

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = second_added_commit_message
          commit.add_files([
            {
              file_path: "file-#{SecureRandom.hex(8)}",
              content: 'This should exist on one node before reconciliation'
            }
          ])
        end

        # Confirm that we have access to the repo after failover,
        # including the commit we just added
        expect(project.commits.map { |commit| commit[:message].chomp })
          .to include(intial_commit_message)
          .and include(first_added_commit_message)
          .and include(second_added_commit_message)
      end

      context 'when recovering from dataloss after failover' do
        it 'automatically reconciles', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347831' do
          # Start the old primary node again
          praefect_manager.start_primary_node
          praefect_manager.wait_for_primary_node_health_check

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
