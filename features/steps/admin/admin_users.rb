class AdminUsers < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedAdmin

  Then 'I should see all users' do
    User.all.each do |user|
      page.should have_content user.name
    end
  end
end
