# frozen_string_literal: true

module QA
  context 'Create' do
    context 'Gitaly' do
      describe 'High Availability', :orchestrated, :gitaly_ha do
        let(:project) do
          Resource::Project.fabricate! do |project|
            project.name = 'gitaly_high_availability'
          end
        end
        let(:initial_file) { 'pushed_to_primary.txt' }
        let(:final_file) { 'pushed_to_secondary.txt' }

        before do
          @praefect_manager = Service::PraefectManager.new
          Flow::Login.sign_in
        end

        after do
          @praefect_manager.reset
        end

        it 'makes sure that automatic failover is happening' do
          Resource::Repository::ProjectPush.fabricate! do |push|
            push.project = project
            push.commit_message = 'pushed to primary gitaly node'
            push.new_branch = true
            push.file_name = initial_file
            push.file_content = "This should exist on both nodes"
          end

          @praefect_manager.stop_primary_node

          project.visit!

          Page::Project::Show.perform do |show|
            show.wait_until do
              show.has_name?(project.name)
            end
            expect(show).to have_file(initial_file)
          end

          Resource::Repository::Commit.fabricate_via_api! do |commit|
            commit.project = project
            commit.add_files([
              {
                file_path: 'committed_to_primary.txt',
                content: 'This should exist on both nodes too'
              }
            ])
          end

          project.visit!

          Page::Project::Show.perform do |show|
            expect(show).to have_file(final_file)
          end
        end
      end
    end
  end
end
