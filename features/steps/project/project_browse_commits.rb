class ProjectBrowseCommits < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  Then 'I see project commits' do
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
    fill_in "from", with: "8716fc78f3c65bbf7bcf7b574febd583bc5d2812"
    fill_in "to",   with: "bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a"
    click_button "Compare"
  end

  Then 'I see compared refs' do
    page.should have_content "Compare View"
    page.should have_content "Commits (1)"
    page.should have_content "Showing 2 changed files"
  end

  Then 'I see breadcrumb links' do
    page.should have_selector('ul.breadcrumb')
    page.should have_selector('ul.breadcrumb span.divider', count: 3)
    page.should have_selector('ul.breadcrumb a', count: 4)

    find('ul.breadcrumb li:first a')['href'].should match(/#{@project.path}\/commits\/master\z/)
    find('ul.breadcrumb li:last a')['href'].should match(%r{master/app/models/project\.rb\z})
  end

  Then 'I see commits stats' do
    page.should have_content 'Stats'
    page.should have_content 'Committers'
    page.should have_content 'Total commits'
    page.should have_content 'Authors'
  end
end
