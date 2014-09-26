class Spinach::Features::User < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedUser
  include SharedProject

  step 'I should see user "John Doe" page' do
    expect(title).to match(/^\s*John Doe/)
  end
end
