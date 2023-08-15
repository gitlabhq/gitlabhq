# frozen_string_literal: true

module QA
  RSpec.describe 'Verify' do
    describe 'Pipeline editor', product_group: :pipeline_authoring do
      let(:project) { create(:project, :with_readme, name: 'pipeline-editor-project') }

      before do
        Flow::Login.sign_in
        project.visit!
        Page::Project::Menu.perform(&:go_to_pipeline_editor)
      end

      after do
        project&.remove_via_api!
      end

      it(
        'can create merge request',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/349130'
      ) do
        Page::Project::PipelineEditor::New.perform(&:create_new_ci)

        Page::Project::PipelineEditor::Show.perform do |show|
          # The new MR checkbox is visible after a new branch name is set
          show.set_source_branch(SecureRandom.hex(10))
          expect(show).to have_new_mr_checkbox

          show.select_new_mr_checkbox
          show.submit_changes
        end

        Page::MergeRequest::New.perform(&:create_merge_request)

        Page::MergeRequest::Show.perform do |show|
          expect(show).to have_title('Update .gitlab-ci.yml file')
        end
      end
    end
  end
end
