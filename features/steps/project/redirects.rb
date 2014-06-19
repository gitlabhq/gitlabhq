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
    within '.project-home-title' do
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
    click_link "Sign in"
  end

  step 'I should be redirected to "Community" page' do
    project = Project.find_by(name: 'Community')
    page.current_path.should == "/#{project.path_with_namespace}"
    page.status_code.should == 200
  end
end

