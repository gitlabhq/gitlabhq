class ProjectWall < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedNote
  include SharedPaths


  Given 'I write new comment "my special test message"' do
    within(".wall-note-form") do
      fill_in "note[note]", with: "my special test message"
      click_button "Add Comment"
    end
  end

  Then 'I should see project wall note "my special test message"' do
    page.should have_content "my special test message"
  end
end
