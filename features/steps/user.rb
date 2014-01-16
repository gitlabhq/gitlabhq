class Spinach::Features::User < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedUser
  include Shared

  step 'I should see user "John Van Public" page' do
    expect(page.title).to match(/^\s*John Van Public/)
  end

  step 'I should see user "John Van Internal" page' do
    expect(page.title).to match(/^\s*John Van Internal/)
  end

  step 'I should see user "John Van Private" page' do
    expect(page.title).to match(/^\s*John Van Private/)
  end

  step 'I sign in as "John Van Private"' do
    login_with(User.find_by(name:"John Van Private"))
  end
end
