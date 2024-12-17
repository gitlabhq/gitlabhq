# frozen_string_literal: true

module QA
  RSpec.describe 'Verify' do
    describe 'Update CI file with pipeline editor', product_group: :pipeline_authoring do
      let(:new_branch_name) { SecureRandom.hex(10) }
      let(:project) { create(:project, name: 'pipeline-editor-project') }

      let!(:commit) do
        create(:commit, project: project, commit_message: 'Add .gitlab-ci.yml', actions: [
          {
            action: 'create',
            file_path: '.gitlab-ci.yml',
            content: <<~YAML
              'This is to make pipeline fail immediately to save test execution time and resources.'
            YAML
          }
        ])
      end

      let(:new_content) do
        <<~YAML
          'This is to do the exact same thing as the above.'
        YAML
      end

      before do
        Flow::Login.sign_in
        project.visit!
        Support::Waiter.wait_until(message: 'Wait for first pipeline to be created') { project.pipelines.size == 1 }

        edit_ci_file_content_and_create_merge_request
      end

      it 'creates new pipelines, target branch, and merge request',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/349005' do
        # Verify a new MR is created from the update
        Page::MergeRequest::Show.perform do |show|
          expect(show).to have_title('Update .gitlab-ci.yml file')
        end

        # The target branch is also created and new pipeline respectively
        aggregate_failures do
          expect(project).to have_branch(new_branch_name)
          expect { project.pipelines.size > 1 }.to eventually_be_truthy
        end
      end

      private

      def edit_ci_file_content_and_create_merge_request
        Page::Project::Menu.perform(&:go_to_pipeline_editor)
        Support::WaitForRequests.wait_for_requests

        Page::Project::PipelineEditor::Show.perform do |show|
          show.write_to_editor(new_content)
          show.set_source_branch(new_branch_name)
          show.select_new_mr_checkbox
          show.submit_changes
        end

        Page::MergeRequest::New.perform(&:create_merge_request)
      end
    end
  end
end
