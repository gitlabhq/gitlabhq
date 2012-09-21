class ProjectBrowseCommits < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  Then 'I see project commits' do
    current_path.should == project_commits_path(@project)

    commit = @project.commit
    page.should have_content(@project.name)
    page.should have_content(commit.message)
    page.should have_content(commit.id.to_s[0..5])
  end

  Given 'I click atom feed link' do
    click_link "Feed"
  end

  Then 'I see commits atom feed' do
    commit = CommitDecorator.decorate(@project.commit)
    page.response_headers['Content-Type'].should have_content("application/atom+xml")
    page.body.should have_selector("title", :text => "Recent commits to #{@project.name}")
    page.body.should have_selector("author email", :text => commit.author_email)
    page.body.should have_selector("entry summary", :text => commit.description)
  end

  Given 'I click on commit link' do
    visit project_commit_path(@project, ValidCommit::ID)
  end

  Then 'I see commit info' do
    page.should have_content ValidCommit::MESSAGE
    page.should have_content "Showing 1 changed file"
  end

  And 'I fill compare fields with refs' do
    fill_in "from", :with => "master"
    fill_in "to", :with => "stable"
    click_button "Compare"
  end

  And 'I see compared refs' do
    page.should have_content "Commits (27)"
    page.should have_content "Compare View"
    page.should have_content "Showing 73 changed files"
  end
end
