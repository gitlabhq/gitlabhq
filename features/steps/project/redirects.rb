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
    visit namespace_project_path(project.namespace, project)
  end

  step 'I should see project "Community" home page' do
    expect(Gitlab.config.gitlab).to receive(:host).and_return("www.example.com")
    page.within '.navbar-gitlab .title' do
      expect(page).to have_content 'Community'
    end
  end

  step 'I visit project "Enterprise" page' do
    project = Project.find_by(name: 'Enterprise')
    visit namespace_project_path(project.namespace, project)
  end

  step 'I visit project "CommunityDoesNotExist" page' do
    project = Project.find_by(name: 'Community')
    visit namespace_project_path(project.namespace, project) + 'DoesNotExist'
  end

  step 'I click on "Sign In"' do
    first(:link, "Sign in").click
  end

  step 'Authenticate' do
    admin = create(:admin)
    fill_in "user_login", with: admin.email
    fill_in "user_password", with: admin.password
    click_button "Sign in"
    Thread.current[:current_user] = admin
  end

  step 'I should be redirected to "Community" page' do
    project = Project.find_by(name: 'Community')
    expect(current_path).to eq "/#{project.path_with_namespace}"
    expect(status_code).to eq 200
  end

  step 'I get redirected to signin page where I sign in' do
    admin = create(:admin)
    fill_in "user_login", with: admin.email
    fill_in "user_password", with: admin.password
    click_button "Sign in"
    Thread.current[:current_user] = admin
  end

  step 'I should be redirected to "Enterprise" page' do
    project = Project.find_by(name: 'Enterprise')
    expect(current_path).to eq "/#{project.path_with_namespace}"
    expect(status_code).to eq 200
  end
end
