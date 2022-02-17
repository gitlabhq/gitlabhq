# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    context 'Praefect dataloss commands', :orchestrated, :gitaly_cluster do
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

      it 'confirms that changes are synced across all storages', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/352691' do
        expect { praefect_manager.praefect_dataloss_information(project.id) }
        .to(eventually_include('All repositories are fully available on all assigned storages!')
        .within(max_duration: 60))
      end

      it 'identifies how many changes are not in sync across storages', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/352692' do
        # Ensure our test repository is replicated and in a consistent state prior to test
        praefect_manager.wait_for_project_synced_across_all_storages(project.id)

        # testing for gitaly2 'out of sync'
        praefect_manager.stop_secondary_node

        number_of_changes = 3
        1.upto(number_of_changes) do |i|
          Resource::Repository::Commit.fabricate_via_api! do |commit|
            commit.project = project
            commit.branch = "newbranch-#{SecureRandom.hex(8)}"
            commit.start_branch = project.default_branch
            commit.commit_message = 'Add new file'
            commit.add_files([
              { file_path: "new_file-#{SecureRandom.hex(8)}.txt", content: 'new file' }
            ])
          end
        end

        # testing for gitaly3 'in sync' but marked unhealthy
        praefect_manager.stop_tertiary_node

        project_data_loss = praefect_manager.praefect_dataloss_information(project.id)
        aggregate_failures "validate dataloss identified" do
          expect(project_data_loss).to include('gitaly1, assigned host')
          expect(project_data_loss).to include("gitaly2 is behind by #{number_of_changes} changes or less, assigned host, unhealthy")
          expect(project_data_loss).to include('gitaly3, assigned host, unhealthy')
        end
      end
    end
  end
end
