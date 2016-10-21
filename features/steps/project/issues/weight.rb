class Spinach::Features::ProjectIssuesWeight < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  step 'I click link "New Issue"' do
    click_link "New Issue"
  end

  step 'I submit new issue "500 error on profile" with weight' do
    fill_in "issue_title", with: "500 error on profile"

    click_button 'Weight'

    page.within '.dropdown-menu-weight' do
      click_link '7'
    end

    click_button "Submit issue"
  end

  step 'I should see issue "500 error on profile" with weight' do
    issue = Issue.find_by(title: "500 error on profile")

    page.within '.weight' do
      expect(page).to have_content '7'
    end

    expect(page).to have_content issue.title
  end
end
