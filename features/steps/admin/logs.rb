class Spinach::Features::AdminLogs < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedAdmin

  step 'I should see tabs with available logs' do
    page.should have_content 'production.log'
    page.should have_content 'githost.log'
    page.should have_content 'application.log'
  end
end
