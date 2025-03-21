# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'File templates', product_group: :source_code do
      include Runtime::Fixtures

      let(:project) do
        create(:project,
          :with_readme,
          name: 'file-template-project',
          description: 'Add file templates via the Files view')
      end

      let(:template_file_name) { '.gitlab-ci.yml' }
      let(:template_name) { 'Julia' }

      before do
        Flow::Login.sign_in
        project.visit!
      end

      it "user adds .gitlab-ci.yml via file template Julia",
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347658' do
        content = fetch_template_from_api('gitlab_ci_ymls', 'Julia')

        Page::Project::Show.perform(&:create_new_file!)
        Page::File::Form.perform do |form|
          form.add_custom_name(template_file_name)
          form.select_template(template_file_name, template_name)

          expect(form).to have_normalized_ws_text(content[0..100])
          form.click_commit_changes_in_header
          form.commit_changes_through_modal

          aggregate_failures "indications of file created" do
            expect(form).to have_content(template_file_name)
            expect(form).to have_normalized_ws_text(content[0..100])
            expect(form).to have_content('Add new file')
          end
        end
      end
    end
  end
end
