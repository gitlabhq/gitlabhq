class Spinach::Features::PublicProjectsFeature < Spinach::FeatureSteps
  include SharedPaths

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
    create :project_with_code, name: 'Community', public: true
  end

  step 'public empty project "Empty Public Project"' do
    create :project, name: 'Empty Public Project', public: true
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

  step 'private project "Enterprise"' do
    create :project, name: 'Enterprise'
  end

  step 'I should see project "Community" home page' do
    within '.project-home-title' do
      page.should have_content 'Community'
    end
  end

  private

  def project
    @project ||= Project.find_by_name("Community")
  end
end

