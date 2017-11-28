module QA
  feature "protect a branch", :core do
    scenario "can be protected" do
      Page::Main::Entry.act { visit_login_page }
      Page::Main::Login.act { sign_in_using_credentials }

      Scenario::Gitlab::Project::Repository::Branch::Create.perform do |branch|
        branch.ref = 'master'
        branch.name = 'awesome-branch'
      end

      Page::Project::Menu.act { go_to_settings }
      Page::Project::Settings::Menu.act { go_to_repository }
      Page::Project::Settings::Repository.perform do |settings|
        settings.protect_branch
      end
    end
  end
end
