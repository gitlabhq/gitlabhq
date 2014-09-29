class Spinach::Features::ProjectRedirects < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject

  step 'public project "Community"' do
    create :project, :public, name: 'Community'
  end

  step 'private project "Enterprise"' do
    create :project, name: 'Enterprise'
  end

  step 'I visit project "Community" page' do
    project = Project.find_by(name: 'Community')
    visit project_path(project)
  end

  step 'I should see project "Community" home page' do
    Gitlab.config.gitlab.stub(:host).and_return("www.example.com")
    within '.navbar-gitlab .title' do
      page.should have_content 'Community'
    end
  end

  step 'I visit project "Enterprise" page' do
    project = Project.find_by(name: 'Enterprise')
    visit project_path(project)
  end

  step 'I visit project "CommunityDoesNotExist" page' do
    project = Project.find_by(name: 'Community')
    visit project_path(project) + 'DoesNotExist'
  end

  step 'I click on "Sign In"' do
    first(:link, "Sign in").click
  end

  step 'Authenticate' do
    admin = create(:admin)
    project = Project.find_by(name: 'Community')
    fill_in "user_login", with: admin.email
    fill_in "user_password", with: admin.password
    click_button "Sign in"
    Thread.current[:current_user] = admin
  end

  step 'I should be redirected to "Community" page' do
    project = Project.find_by(name: 'Community')
    current_path.should == "/#{project.path_with_namespace}"
    status_code.should == 200
  end

  step 'I get redirected to signin page where I sign in' do
    admin = create(:admin)
    project = Project.find_by(name: 'Enterprise')
    fill_in "user_login", with: admin.email
    fill_in "user_password", with: admin.password
    click_button "Sign in"
    Thread.current[:current_user] = admin
  end

  step 'I should be redirected to "Enterprise" page' do
    project = Project.find_by(name: 'Enterprise')
    current_path.should == "/#{project.path_with_namespace}"
    status_code.should == 200
  end
end
