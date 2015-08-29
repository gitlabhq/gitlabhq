class Spinach::Features::AdminHooks < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedAdmin

  step "I submit the form with enabled SSL verification" do
    fill_in 'hook_url', with: 'http://google.com'
    check "Enable SSL verification"
    click_on "Add System Hook"
  end

  step "I see new hook with enabled SSL verification" do
    expect(page).to have_content "SSL Verification: enabled"
  end
end
