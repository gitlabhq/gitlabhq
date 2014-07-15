class ProjectBrowseCommits < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  Then 'I see project commits' do
    commit = @project.repository.commit
    page.should have_content(@project.name)
    page.should have_content(commit.message)
    page.should have_content(commit.id.to_s[0..5])
  end

  Given 'I click atom feed link' do
    click_link "Feed"
  end

  Then 'I see commits atom feed' do
    commit = @project.repository.commit
    page.response_headers['Content-Type'].should have_content("application/atom+xml")
    page.body.should have_selector("title", text: "Recent commits to #{@project.name}")
    page.body.should have_selector("author email", text: commit.author_email)
    page.body.should have_selector("entry summary", text: commit.description)
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
    page.should have_selector('ul.breadcrumb a', count: 4)
  end

  Then 'I see commits stats' do
    page.should have_content 'Top 50 Committers'
    page.should have_content 'Committers'
    page.should have_content 'Total commits'
    page.should have_content 'Authors'
  end

  Given 'I visit big commit page' do
    visit project_commit_path(@project, BigCommits::BIG_COMMIT_ID)
  end

  Then 'I see big commit warning' do
    page.should have_content BigCommits::BIG_COMMIT_MESSAGE
    page.should have_content "Too many changes"
  end

  Given 'I visit huge commit page' do
    visit project_commit_path(@project, BigCommits::HUGE_COMMIT_ID)
  end

  Then 'I see huge commit message' do
    page.should have_content BigCommits::HUGE_COMMIT_MESSAGE
  end

  Given 'I visit a commit with an image that changed' do
    visit project_commit_path(@project, 'cc1ba255d6c5ffdce87a357ba7ccc397a4f4026b')
  end

  Then 'The diff links to both the previous and current image' do
    links = page.all('.two-up span div a')
    links[0]['href'].should =~ %r{blob/bc3735004cb45cec5e0e4fa92710897a910a5957}
    links[1]['href'].should =~ %r{blob/cc1ba255d6c5ffdce87a357ba7ccc397a4f4026b}
  end

  Given 'I click side-by-side diff button' do
    click_link "Side-by-side Diff"
  end

  Then 'I see side-by-side diff button' do
    page.should have_content "Side-by-side Diff"
  end

  Then 'I see inline diff button' do
    page.should have_content "Inline Diff"
  end

end
