module QA
  feature 'create a branch', :core do
    scenario 'user creates a branch' do
      Page::Main::Entry.act { visit_login_page }
      Page::Main::Login.act { sign_in_using_credentials }

      Scenario::Gitlab::Project::Repository::Branch::Create.perform do |branch|
        branch.ref = 'master'
        branch.name = 'awesome-branch'
      end

      expect(page).to have_content(/You pushed to awesome-branch/)
    end
  end
end
