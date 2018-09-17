# frozen_string_literal: true

module QA
  context :manage, :smoke do
    describe 'Project creation' do
      it 'user creates a new project' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.act { sign_in_using_credentials }

        group = Factory::Resource::Group.fabricate!
        group.visit!
        Page::Group::Show.act { go_to_new_project }

        name = "awesome-project-#{SecureRandom.hex(8)}"

        Page::Project::New.perform do |page|
          page.choose_test_namespace
          page.choose_name(name)
          page.add_description('create awesome project test')
          page.set_visibility('Public')
          page.create_new_project
        end

        expect(page).to have_content(name)
        expect(page).to have_content(
          /Project \S?awesome-project\S+ was successfully created/
        )
        expect(page).to have_content('create awesome project test')
        expect(page).to have_content('The repository for this project is empty')
      end
    end
  end
end
