module QA
  feature 'create a new branch', :core do
    scenario 'user creates a new branch' do
      Page::Main::Entry.act { visit_login_page }

      Scenario::Gitlab::Project::Create.perform do |project|
        project.name = 'awesome-project'
        project.description = 'create awesome project test'
      end

      Scenario::Gitlab::Repository::CreateBranch.perform do |branch|
        branch.name = 'awesome-branch'
        branch.ref = 'master'
      end

      expect(page).to have_content(
        /Project \S?awesome-project\S+ was successfully created/
      )

      expect(page).to have_content('create awesome project test')
      expect(page).to have_content('The repository for this project is empty')
    end
  end
end
