# frozen_string_literal: true

# TODO: remove this test when coverage is replaced or deemed irrelevant
module QA
  RSpec.describe 'Create', :skip_live_env, product_group: :ide do
    before do
      skip("Skipped but kept as reference. https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115741#note_1330720944")
    end

    describe 'Web IDE file templates' do
      include Runtime::Fixtures

      before(:all) do
        @project = Resource::Project.fabricate_via_api! do |project|
          project.name = 'file-template-project'
          project.description = 'Add file templates via the Web IDE'
          project.initialize_with_readme = true
        end
      end

      templates = [
        {
          file_name: '.gitignore',
          name: 'Android',
          api_path: 'gitignores',
          api_key: 'Android',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347752'
        },
        {
          file_name: '.gitlab-ci.yml',
          name: 'Julia',
          api_path: 'gitlab_ci_ymls',
          api_key: 'Julia',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347753'
        },
        {
          file_name: 'Dockerfile',
          name: 'Python',
          api_path: 'dockerfiles',
          api_key: 'Python',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347750'
        },
        {
          file_name: 'LICENSE',
          name: 'Mozilla Public License 2.0',
          api_path: 'licenses',
          api_key: 'mpl-2.0',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347751'
        }
      ]

      templates.each do |template|
        it "user adds #{template[:file_name]} via file template #{template[:name]}", testcase: template[:testcase] do
          content = fetch_template_from_api(template[:api_path], template[:api_key])

          Flow::Login.sign_in

          @project.visit!

          Page::Project::Show.perform(&:open_web_ide!)
          Page::Project::WebIDE::Edit.perform do |ide|
            ide.wait_until_ide_loads
            ide.create_new_file_from_template template[:file_name], template[:name]

            expect(ide.has_file?(template[:file_name])).to be_truthy
            expect(ide).to have_button('Undo')
            expect(ide).to have_normalized_ws_text(content[0..100])

            ide.rename_file(template[:file_name], "#{SecureRandom.hex(8)}/#{template[:file_name]}")

            ide.commit_changes

            expect(ide).to have_content(template[:file_name])
            expect(ide).to have_normalized_ws_text(content[0..100])
          end
        end
      end
    end
  end
end
