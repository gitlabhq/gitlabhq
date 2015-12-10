class Spinach::Features::ProjectIssuesWeight < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  step 'I click link "New Issue"' do
    click_link "New Issue"
  end

  step 'I submit new issue "500 error on profile" with weight' do
    fill_in "issue_title", with: "500 error on profile"
    fill_in "issue_weight", with: 7
    click_button "Submit new issue"
  end

  step 'I should see issue "500 error on profile" with weight' do
    issue = Issue.find_by(title: "500 error on profile")

    page.within '.weight' do
      expect(page).to have_content '7'
    end

    expect(page).to have_content issue.title
  end
end
