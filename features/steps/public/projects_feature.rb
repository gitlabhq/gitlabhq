class Spinach::Features::PublicProjectsFeature < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject

  step 'I should see project "Community"' do
    page.should have_content "Community"
  end

  step 'I should not see project "Enterprise"' do
    page.should_not have_content "Enterprise"
  end

  step 'I should see project "Empty Public Project"' do
    page.should have_content "Empty Public Project"
  end

  step 'I should see public project details' do
    page.should have_content '32 branches'
    page.should have_content '16 tags'
  end

  step 'I should see project readme' do
    page.should have_content 'README.md'
  end

  step 'public project "Community"' do
    create :project_with_code, name: 'Community', visibility_level: Gitlab::VisibilityLevel::PUBLIC
  end

  step 'public empty project "Empty Public Project"' do
    create :project, name: 'Empty Public Project', visibility_level: Gitlab::VisibilityLevel::PUBLIC
  end

  step 'I visit empty project page' do
    project = Project.find_by_name('Empty Public Project')
    visit project_path(project)
  end

  step 'I visit project "Community" page' do
    project = Project.find_by_name('Community')
    visit project_path(project)
  end

  step 'I should see empty public project details' do
    page.should have_content 'Git global setup'
  end

  step 'I should see empty public project details with http clone info' do
    project = Project.find_by_name('Empty Public Project')
    page.all(:css, '.git-empty .clone').each do |element|
      element.text.should include(project.http_url_to_repo)
    end
  end

  step 'I should see empty public project details with ssh clone info' do
    project = Project.find_by_name('Empty Public Project')
    page.all(:css, '.git-empty .clone').each do |element|
      element.text.should include(project.url_to_repo)
    end
  end

  step 'private project "Enterprise"' do
    create :project, name: 'Enterprise'
  end

  step 'I visit project "Enterprise" page' do
    project = Project.find_by_name('Enterprise')
    visit project_path(project)
  end

  step 'I should see project "Community" home page' do
    within '.project-home-title' do
      page.should have_content 'Community'
    end
  end

  step 'internal project "Internal"' do
    create :project_with_code, name: 'Internal', visibility_level: Gitlab::VisibilityLevel::INTERNAL
  end

  step 'I should see project "Internal"' do
    page.should have_content "Internal"
  end

  step 'I should not see project "Internal"' do
    page.should_not have_content "Internal"
  end

  step 'I visit project "Internal" page' do
    project = Project.find_by_name('Internal')
    visit project_path(project)
  end

  step 'I should see project "Internal" home page' do
    within '.project-home-title' do
      page.should have_content 'Internal'
    end
  end

  step 'I should see an http link to the repository' do
    project = Project.find_by_name 'Community'
    page.should have_field('project_clone', with: project.http_url_to_repo)
  end

  step 'I should see an ssh link to the repository' do
    project = Project.find_by_name 'Community'
    page.should have_field('project_clone', with: project.url_to_repo)
  end
end

