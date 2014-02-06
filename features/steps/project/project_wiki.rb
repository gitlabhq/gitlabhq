class ProjectWiki < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedNote
  include SharedPaths

  Given 'I click on the Cancel button' do
    within(:css, ".form-actions") do
      click_on "Cancel"
    end
  end

  Then 'I should be redirected back to the Edit Home Wiki page' do
    url = URI.parse(current_url)
    url.path.should == project_wiki_path(project, :home)
  end

  Given 'I create the Wiki Home page' do
    fill_in "Content", with: '[link test](test)'
    click_on "Create page"
  end

  Then 'I should see the newly created wiki page' do
    page.should have_content "Home"
    page.should have_content "link test"

    click_link "link test"
    page.should have_content "Editing"
  end

  Given 'I have an existing Wiki page' do
    wiki.create_page("existing", "content", :markdown, "first commit")
    @page = wiki.find_page("existing")
  end

  And 'I browse to that Wiki page' do
    visit project_wiki_path(project, @page)
  end

  And 'I click on the Edit button' do
    click_on "Edit"
  end

  And 'I change the content' do
    fill_in "Content", with: 'Updated Wiki Content'
    click_on "Save changes"
  end

  Then 'I should see the updated content' do
    page.should have_content "Updated Wiki Content"
  end

  Then 'I should be redirected back to that Wiki page' do
    url = URI.parse(current_url)
    url.path.should == project_wiki_path(project, @page)
  end

  And 'That page has two revisions' do
    @page.update("new content", :markdown, "second commit")
  end

  And 'I click the History button' do
    click_on "History"
  end

  Then 'I should see both revisions' do
    page.should have_content current_user.name
    page.should have_content "first commit"
    page.should have_content "second commit"
  end

  And 'I click on the "Delete this page" button' do
    click_on "Delete this page"
  end

  Then 'The page should be deleted' do
    page.should have_content "Page was successfully deleted"
  end

  And 'I click on the "Pages" button' do
    click_on "Pages"
  end

  Then 'I should see the existing page in the pages list' do
    page.should have_content current_user.name
    page.should have_content @page.title.titleize
  end

  def wiki
    @gollum_wiki = GollumWiki.new(project, current_user)
  end
end
