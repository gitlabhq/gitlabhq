class Spinach::Features::ExploreProjects < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject
  include SharedUser

  step 'I should see project "Empty Public Project"' do
    expect(page).to have_content "Empty Public Project"
  end

  step 'I should see public project details' do
    expect(page).to have_content '32 branches'
    expect(page).to have_content '16 tags'
  end

  step 'I should see project readme' do
    expect(page).to have_content 'README.md'
  end

  step 'I should see empty public project details' do
    expect(page).not_to have_content 'Git global setup'
  end

  step 'I should see empty public project details with http clone info' do
    project = Project.find_by(name: 'Empty Public Project')
    page.all(:css, '.git-empty .clone').each do |element|
      expect(element.text).to include(project.http_url_to_repo)
    end
  end

  step 'I should see empty public project details with ssh clone info' do
    project = Project.find_by(name: 'Empty Public Project')
    page.all(:css, '.git-empty .clone').each do |element|
      expect(element.text).to include(project.url_to_repo)
    end
  end

  step 'I should see project "Community" home page' do
    page.within '.navbar-gitlab .title' do
      expect(page).to have_content 'Community'
    end
  end

  step 'I should see project "Internal" home page' do
    page.within '.navbar-gitlab .title' do
      expect(page).to have_content 'Internal'
    end
  end

  step 'I should see an http link to the repository' do
    project = Project.find_by(name: 'Community')
    expect(page).to have_field('project_clone', with: project.http_url_to_repo)
  end

  step 'I should see an ssh link to the repository' do
    project = Project.find_by(name: 'Community')
    expect(page).to have_field('project_clone', with: project.url_to_repo)
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
    visit namespace_project_issues_path(public_project.namespace, public_project)
  end


  step 'I should see list of issues for "Community" project' do
    expect(page).to have_content "Bug"
    expect(page).to have_content public_project.name
    expect(page).to have_content "New feature"
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
    visit namespace_project_issues_path(internal_project.namespace, internal_project)
  end


  step 'I should see list of issues for "Internal" project' do
    expect(page).to have_content "Internal Bug"
    expect(page).to have_content internal_project.name
    expect(page).to have_content "New internal feature"
  end

  step 'I visit "Community" merge requests page' do
    visit namespace_project_merge_requests_path(public_project.namespace, public_project)
  end

  step 'project "Community" has "Bug fix" open merge request' do
    create(:merge_request,
      title: "Bug fix for public project",
      source_project: public_project,
      target_project: public_project,
          )
  end

  step 'I should see list of merge requests for "Community" project' do
    expect(page).to have_content public_project.name
    expect(page).to have_content public_merge_request.source_project.name
  end

  step 'I visit "Internal" merge requests page' do
    visit namespace_project_merge_requests_path(internal_project.namespace, internal_project)
  end

  step 'project "Internal" has "Feature implemented" open merge request' do
    create(:merge_request,
      title: "Feature implemented",
      source_project: internal_project,
      target_project: internal_project
          )
  end

  step 'I should see list of merge requests for "Internal" project' do
    expect(page).to have_content internal_project.name
    expect(page).to have_content internal_merge_request.source_project.name
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
