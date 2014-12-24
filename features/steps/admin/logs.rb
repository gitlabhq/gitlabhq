class Spinach::Features::AdminLogs < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedAdmin

  step 'I should see tabs with available logs' do
    expect(page).to have_content 'production.log'
    expect(page).to have_content 'githost.log'
    expect(page).to have_content 'application.log'
  end
end
