class Spinach::Features::ProjectSourceSearchCode < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  step 'I search for term "coffee"' do
    fill_in "search", with: "coffee"
    click_button "Go"
  end

  step 'I should see files from repository containing "coffee"' do
    expect(page).to have_content 'coffee'
    expect(page).to have_content 'CONTRIBUTING.md'
  end

  step 'I should see empty result' do
    expect(page).to have_content "We couldn't find any"
  end
end
