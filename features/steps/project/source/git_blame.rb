class Spinach::Features::ProjectSourceGitBlame < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  step 'I click on ".gitignore" file in repo' do
    click_link ".gitignore"
  end

  step 'I click Blame button' do
    click_link 'Blame'
  end

  step 'I should see git file blame' do
    expect(page).to have_content "*.rb"
    expect(page).to have_content "Dmitriy Zaporozhets"
    expect(page).to have_content "Initial commit"
  end
end
