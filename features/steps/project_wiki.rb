class ProjectWiki < Spinach::FeatureSteps
  Given 'I create Wiki page' do
    fill_in "Title", :with => 'Test title'
    fill_in "Content", :with => '[link test](test)'
    click_on "Save"
  end

  Then 'I should see newly created wiki page' do
    page.should have_content "Test title"
    page.should have_content "link test"

    click_link "link test"
    page.should have_content "Editing page"
  end

  And 'I leave a comment like "XML attached"' do
    fill_in "note_note", :with => "XML attached"
    click_button "Add Comment"
  end

  Then 'I should see comment "XML attached"' do
    page.should have_content "XML attached"
  end

  Given 'I sign in as a user' do
    login_as :user
  end

  And 'I own project "Shop"' do
    @project = Factory :project, :name => "Shop"
    @project.add_access(@user, :admin)
  end

  Given 'I visit project wiki page' do
    visit project_wiki_path(@project, :index)
  end
end
