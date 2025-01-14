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

      templates = [
        {
          file_name: '.gitignore',
          name: 'Android',
          api_path: 'gitignores',
          api_key: 'Android',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347659'
        },
        {
          file_name: '.gitlab-ci.yml',
          name: 'Julia',
          api_path: 'gitlab_ci_ymls',
          api_key: 'Julia',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347658'
        },
        {
          file_name: 'Dockerfile',
          name: 'Python',
          api_path: 'dockerfiles',
          api_key: 'Python',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347660'
        },
        {
          file_name: 'LICENSE',
          name: 'Mozilla Public License 2.0',
          api_path: 'licenses',
          api_key: 'mpl-2.0',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347657'
        }
      ]

      templates.each do |template|
        it "user adds #{template[:file_name]} via file template #{template[:name]}", testcase: template[:testcase] do
          content = fetch_template_from_api(template[:api_path], template[:api_key])

          Flow::Login.sign_in

          project.visit!

          Page::Project::Show.perform(&:create_new_file!)
          Page::File::Form.perform do |form|
            form.add_custom_name(template[:file_name])
            form.select_template template[:file_name], template[:name]

            expect(form).to have_normalized_ws_text(content[0..100])
            form.click_commit_changes_in_header
            form.commit_changes_through_modal

            aggregate_failures "indications of file created" do
              expect(form).to have_content(template[:file_name])
              expect(form).to have_normalized_ws_text(content[0..100])
              expect(form).to have_content('Add new file')
            end
          end
        end
      end
    end
  end
end
