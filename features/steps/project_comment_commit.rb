class ProjectCommentCommit < Spinach::FeatureSteps
  Given 'I leave a comment like "XML attached"' do
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

  Given 'I visit project commit page' do
    visit project_commit_path(@project, ValidCommit::ID)
  end
end
