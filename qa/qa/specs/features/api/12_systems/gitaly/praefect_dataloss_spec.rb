# frozen_string_literal: true

module QA
  RSpec.describe 'Systems' do
    describe 'Praefect dataloss commands', :orchestrated, :gitaly_cluster, product_group: :gitaly do
      let(:praefect_manager) { Service::PraefectManager.new }

      let(:project) do
        Resource::Project.fabricate! do |project|
          project.name = 'gitaly_cluster-dataloss-project'
          project.initialize_with_readme = true
        end
      end

      before do
        praefect_manager.start_all_nodes
      end

      it 'confirms that changes are synced across all storages',
         testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/352691' do
        expect { praefect_manager.praefect_dataloss_information(project.id) }
        .to(eventually_include('All repositories are fully available on all assigned storages!')
        .within(max_duration: 60))
      end

      it 'identifies how many changes are not in sync across storages',
         testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/352692' do
        # Ensure our test repository is replicated and in a consistent state prior to test
        praefect_manager.wait_for_project_synced_across_all_storages(project.id)

        # testing for gitaly2 'out of sync'
        praefect_manager.stop_node(praefect_manager.secondary_node)

        number_of_changes = 3
        1.upto(number_of_changes) do |i|
          Resource::Repository::Commit.fabricate_via_api! do |commit|
            commit.project = project
            commit.branch = "newbranch-#{SecureRandom.hex(8)}"
            commit.start_branch = project.default_branch
            commit.commit_message = 'Add new file'
            commit.add_files(
              [{
                file_path: "new_file-#{SecureRandom.hex(8)}.txt", content: 'new file'
              }]
            )
          end
        end

        # testing for gitaly3 'in sync' but marked unhealthy
        praefect_manager.stop_node(praefect_manager.tertiary_node)

        project_data_loss = praefect_manager.praefect_dataloss_information(project.id)
        aggregate_failures "validate dataloss identified" do
          expect(project_data_loss).to include('gitaly1, assigned host')
          expect(project_data_loss)
            .to include("gitaly2 is behind by #{number_of_changes} changes or less, assigned host, unhealthy")
          expect(project_data_loss).to include('gitaly3, assigned host, unhealthy')
        end
      end

      it 'allows admin resolve scenario where data cannot be recovered',
         testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/352708' do
        # Ensure everything is in sync before begining test
        praefect_manager.wait_for_project_synced_across_all_storages(project.id)

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'accept-dataloss-1'
          commit.add_files(
            [{
              file_path: "new_file-#{SecureRandom.hex(8)}.txt", content: 'Add a commit to gitaly1,gitaly2,gitaly3'
            }]
          )
        end

        praefect_manager.wait_for_replication_to_node(project.id, praefect_manager.primary_node)
        praefect_manager.stop_node(praefect_manager.primary_node)
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'accept-dataloss-2'
          commit.add_files(
            [{
              file_path: "new_file-#{SecureRandom.hex(8)}.txt", content: 'Add a commit to gitaly2,gitaly3'
            }]
          )
        end

        praefect_manager.wait_for_replication_to_node(project.id, praefect_manager.secondary_node)
        praefect_manager.stop_node(praefect_manager.secondary_node)
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'accept-dataloss-3'
          commit.add_files([
                             { file_path: "new_file-#{SecureRandom.hex(8)}.txt", content: 'Add a commit to gitaly3' }
                           ])
        end

        # Confirms that they want to accept dataloss, using gitaly2 as authoritative storage to use as a base
        praefect_manager.accept_dataloss_for_project(project.id, praefect_manager.secondary_node)

        # Restart nodes, and allow replication to apply dataloss changes
        praefect_manager.start_all_nodes
        praefect_manager.wait_for_project_synced_across_all_storages(project.id)

        # Validate that gitaly2 was accepted as the authorative storage
        aggregate_failures "validate correct set of commits available" do
          expect(project.commits.map { |commit| commit[:message].chomp }).to include('accept-dataloss-1')
          expect(project.commits.map { |commit| commit[:message].chomp }).to include('accept-dataloss-2')
          expect(project.commits.map { |commit| commit[:message].chomp }).not_to include('accept-dataloss-3')
        end
      end
    end
  end
end
