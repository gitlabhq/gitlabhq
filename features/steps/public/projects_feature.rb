class Spinach::Features::PublicProjectsFeature < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject

  step 'public empty project "Empty Public Project"' do
    create :empty_project, name: 'Empty Public Project', visibility_level: Gitlab::VisibilityLevel::PUBLIC
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

  step 'I visit empty project page' do
    project = Project.find_by(name: 'Empty Public Project')
    visit project_path(project)
  end

  step 'I visit project "Community" page' do
    project = Project.find_by(name: 'Community')
    visit project_path(project)
  end

  step 'I should see empty public project details' do
    page.should have_content 'Git global setup'
  end

  step 'I should see empty public project details with http clone info' do
    project = Project.find_by(name: 'Empty Public Project')
    page.all(:css, '.git-empty .clone').each do |element|
      element.text.should include(project.http_url_to_repo)
    end
  end

  step 'I should see empty public project details with ssh clone info' do
    project = Project.find_by(name: 'Empty Public Project')
    page.all(:css, '.git-empty .clone').each do |element|
      element.text.should include(project.url_to_repo)
    end
  end

  step 'I visit project "Enterprise" page' do
    project = Project.find_by(name: 'Enterprise')
    visit project_path(project)
  end

  step 'I should see project "Community" home page' do
    within '.project-home-title' do
      page.should have_content 'Community'
    end
  end

  step 'I visit project "Internal" page' do
    project = Project.find_by(name: 'Internal')
    visit project_path(project)
  end

  step 'I should see project "Internal" home page' do
    within '.project-home-title' do
      page.should have_content 'Internal'
    end
  end

  step 'I should see an http link to the repository' do
    project = Project.find_by(name: 'Community')
    page.should have_field('project_clone', with: project.http_url_to_repo)
  end

  step 'I should see an ssh link to the repository' do
    project = Project.find_by(name: 'Community')
    page.should have_field('project_clone', with: project.url_to_repo)
  end

  step 'I visit "Community" issues page' do
    create(:issue,
       title: "Bug",
       project: public_project
      )
    create(:issue,
       title: "New feature",
       project: public_project
      )
    visit project_issues_path(public_project)
  end


  step 'I should see list of issues for "Community" project' do
    page.should have_content "Bug"
    page.should have_content public_project.name
    page.should have_content "New feature"
  end

  step 'I visit "Internal" issues page' do
    create(:issue,
       title: "Internal Bug",
       project: internal_project
      )
    create(:issue,
       title: "New internal feature",
       project: internal_project
      )
    visit project_issues_path(internal_project)
  end


  step 'I should see list of issues for "Internal" project' do
    page.should have_content "Internal Bug"
    page.should have_content internal_project.name
    page.should have_content "New internal feature"
  end

  step 'I visit "Community" merge requests page' do
    visit project_merge_requests_path(public_project)
  end

  step 'project "Community" has "Bug fix" open merge request' do
    create(:merge_request,
      title: "Bug fix for public project",
      source_project: public_project,
      target_project: public_project,
    )
  end

  step 'I should see list of merge requests for "Community" project' do
    page.should have_content public_project.name
    page.should have_content public_merge_request.source_project.name
  end

  step 'I visit "Internal" merge requests page' do
    visit project_merge_requests_path(internal_project)
  end

  step 'project "Internal" has "Feature implemented" open merge request' do
    create(:merge_request,
      title: "Feature implemented",
      source_project: internal_project,
      target_project: internal_project
    )
  end

  step 'I should see list of merge requests for "Internal" project' do
    page.should have_content internal_project.name
    page.should have_content internal_merge_request.source_project.name
  end

  def internal_project
    @internal_project ||= Project.find_by!(name: 'Internal')
  end

  def public_project
    @public_project ||= Project.find_by!(name: 'Community')
  end


  def internal_merge_request
    @internal_merge_request ||= MergeRequest.find_by!(title: 'Feature implemented')
  end

  def public_merge_request
    @public_merge_request ||= MergeRequest.find_by!(title: 'Bug fix for public project')
  end
end

