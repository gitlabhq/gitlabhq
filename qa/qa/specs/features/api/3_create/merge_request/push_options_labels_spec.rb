# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Merge request push options' do
      # If run locally on GDK, push options need to be enabled on the host with the following command:
      #
      # git config --global receive.advertisepushoptions true

      branch = "push-options-test-#{SecureRandom.hex(8)}"
      title = "MR push options test #{SecureRandom.hex(8)}"
      commit_message = 'Add README.md'

      project = Resource::Project.fabricate_via_api! do |project|
        project.name = 'merge-request-push-options'
        project.initialize_with_readme = true
      end

      it 'sets labels' do
        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.commit_message = commit_message
          push.branch_name = branch
          push.merge_request_push_options = {
            create: true,
            title: title,
            label: %w[one two three]
          }
        end

        merge_request = project.merge_request_with_title(title)

        expect(merge_request[:labels]).to include('one').and include('two').and include('three')
      end

      context 'when labels are set already' do
        it 'removes them' do
          Resource::Repository::ProjectPush.fabricate! do |push|
            push.project = project
            push.file_content = "Unlabel test #{SecureRandom.hex(8)}"
            push.commit_message = commit_message
            push.branch_name = branch
            push.new_branch = false
            push.merge_request_push_options = {
              title: title,
              unlabel: %w[one three]
            }
          end

          merge_request = project.merge_request_with_title(title)

          aggregate_failures do
            expect(merge_request[:labels]).to include('two')
            expect(merge_request[:labels]).not_to include('one')
            expect(merge_request[:labels]).not_to include('three')
          end
        end
      end
    end
  end
end
