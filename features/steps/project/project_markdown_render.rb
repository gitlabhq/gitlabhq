class Spinach::Features::ProjectMarkdownRender < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths

  And 'I own project "Delta"' do
    @project = Project.find_by_name "Delta"
    @project ||= create(:project_with_code, name: "Delta", namespace: @user.namespace)
    @project.team << [@user, :master]
  end

  Then 'I should see files from repository in master' do
    current_path.should == project_tree_path(@project, "master")
    page.should have_content "Gemfile"
    page.should have_content "app"
    page.should have_content "README"
  end

  And 'I should see rendered README which contains correct links' do
    page.should have_content "Welcome to GitLab GitLab is a free project and repository management application"
    page.should have_link "GitLab API doc"
    page.should have_link "GitLab API website"
    page.should have_link "Rake tasks"
    page.should have_link "backup and restore procedure"
  end

  And 'I click on Gitlab API in README' do
    click_link "GitLab API doc"
  end

  Then 'I should see correct document rendered' do
    current_path.should == project_blob_path(@project, "master/doc/api/README.md")
    page.should have_content "All API requests require authentication"
  end

  And 'I click on Rake tasks in README' do
    click_link "Rake tasks"
  end

  Then 'I should see correct directory rendered' do
    current_path.should == project_tree_path(@project, "master/doc/raketasks")
    page.should have_content "backup_restore.md"
    page.should have_content "maintenance.md"
  end

  And 'I navigate to the doc/api/README' do
    click_link "doc"
    click_link "api"
    click_link "README.md"
  end

  And 'I see correct file rendered' do
    current_path.should == project_blob_path(@project, "master/doc/api/README.md")
    page.should have_content "Contents"
    page.should have_link "Users"
    page.should have_link "Rake tasks"
  end

  And 'I click on users in doc/api/README' do
    click_link "Users"
  end

  Then 'I should see the correct document file' do
    current_path.should == project_blob_path(@project, "master/doc/api/users.md")
    page.should have_content "Get a list of users."
  end

  And 'I click on raketasks in doc/api/README' do
    click_link "Rake tasks"
  end

  When 'I visit markdown branch' do
    visit project_tree_path(@project, "markdown")
  end

  Then 'I should see files from repository in markdown branch' do
    current_path.should == project_tree_path(@project, "markdown")
    page.should have_content "Gemfile"
    page.should have_content "app"
    page.should have_content "README"
  end

  And 'I see correct file rendered in markdown branch' do
    current_path.should == project_blob_path(@project, "markdown/doc/api/README.md")
    page.should have_content "Contents"
    page.should have_link "Users"
    page.should have_link "Rake tasks"
  end

  Then 'I should see correct document rendered for markdown branch' do
    current_path.should == project_blob_path(@project, "markdown/doc/api/README.md")
    page.should have_content "All API requests require authentication"
  end

  Then 'I should see correct directory rendered for markdown branch' do
    current_path.should == project_tree_path(@project, "markdown/doc/raketasks")
    page.should have_content "backup_restore.md"
    page.should have_content "maintenance.md"
  end

  Then 'I should see the users document file in markdown branch' do
    current_path.should == project_blob_path(@project, "markdown/doc/api/users.md")
    page.should have_content "Get a list of users."
  end

  Given 'I go to wiki page' do
    click_link "Wiki"
    current_path.should == project_wiki_path(@project, "home")
  end

  And 'I add various links to the wiki page' do
    fill_in "wiki[content]", with: "[test](test)\n[GitLab API doc](doc/api/README.md)\n[Rake tasks](doc/raketasks)\n"
    fill_in "wiki[message]", with: "Adding links to wiki"
    click_button "Create page"
  end

  Then 'Wiki page should have added links' do
    current_path.should == project_wiki_path(@project, "home")
    page.should have_content "test GitLab API doc Rake tasks"
  end

  And 'I click on test link' do
    click_link "test"
  end

  Then 'I see new wiki page named test' do
    current_path.should ==  project_wiki_path(@project, "test")
    page.should have_content "Editing"
  end

  When 'I go back to wiki page home' do
    visit project_wiki_path(@project, "home")
    current_path.should == project_wiki_path(@project, "home")
  end

  And 'I click on GitLab API doc link' do
    click_link "GitLab API"
  end

  Then 'I see Gitlab API document' do
    current_path.should == project_blob_path(@project, "master/doc/api/README.md")
    page.should have_content "Status codes"
  end

  And 'I click on Rake tasks link' do
    click_link "Rake tasks"
  end

  Then 'I see Rake tasks directory' do
    current_path.should == project_tree_path(@project, "master/doc/raketasks")
    page.should have_content "backup_restore.md"
    page.should have_content "maintenance.md"
  end

  Given 'I visit to the help page' do
    visit help_path
  end

  And 'I select a page with markdown' do
    click_link "Rake Tasks"
  end

  Then 'I should see a help page with markdown' do
    page.should have_content "GitLab provides some specific rake tasks to enable special features or perform maintenance tasks"
  end

  Given 'I go directory which contains README file' do
    visit project_tree_path(@project, "master/doc/api")
    current_path.should == project_tree_path(@project, "master/doc/api")
  end

  And 'I click on a relative link in README' do
    click_link "Users"
  end

  Then 'I should see the correct markdown' do
    current_path.should == project_blob_path(@project, "master/doc/api/users.md")
    page.should have_content "List users"
  end
end
