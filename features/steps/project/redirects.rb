class Spinach::Features::ProjectRedirects < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject

  step 'public project "Community"' do
    create :project_with_code, name: 'Community', visibility_level: Gitlab::VisibilityLevel::PUBLIC
  end

  step 'private project "Enterprise"' do
    create :project, name: 'Enterprise'
  end

  step 'I visit project "Community" page' do
    project = Project.find_by_name('Community')
    visit project_path(project)
  end

  step 'I should see project "Community" home page' do
    within '.project-home-title' do
      page.should have_content 'Community'
    end
  end

  step 'I visit project "Enterprise" page' do
    project = Project.find_by_name('Enterprise')
    visit project_path(project)
  end

  step 'I visit project "CommunityDoesNotExist" page' do
    project = Project.find_by_name('Community')
    visit project_path(project) + 'DoesNotExist'
  end
end

