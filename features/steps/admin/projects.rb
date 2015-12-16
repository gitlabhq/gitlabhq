class Spinach::Features::AdminProjects < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedAdmin
  include SharedProject
  include SharedUser
  include Select2Helper

  step 'I should see all non-archived projects' do
    Project.non_archived.each do |p|
      expect(page).to have_content p.name_with_namespace
    end
  end

  step 'I should see all projects' do
    Project.all.each do |p|
      expect(page).to have_content p.name_with_namespace
    end
  end

  step 'I check "Show archived projects"' do
    page.check 'Show archived projects'
    click_button "Search"
  end

  step 'I should see "archived" label' do
    expect(page).to have_xpath("//span[@class='label label-warning']", text: 'archived')
  end

  step 'I click on first project' do
    click_link Project.first.name_with_namespace
  end

  step 'I should see project details' do
    project = Project.first
    expect(current_path).to eq admin_namespace_project_path(project.namespace, project)
    expect(page).to have_content(project.name_with_namespace)
    expect(page).to have_content(project.creator.name)
  end

  step 'I visit admin project page' do
    visit admin_namespace_project_path(project.namespace, project)
  end

  step 'I transfer project to group \'Web\'' do
    allow_any_instance_of(Projects::TransferService).
      to receive(:move_uploads_to_new_namespace).and_return(true)
    find(:xpath, "//input[@id='new_namespace_id']").set group.id
    click_button 'Transfer'
  end

  step 'group \'Web\'' do
    create(:group, name: 'Web')
  end

  step 'I should see project transfered' do
    expect(page).to have_content 'Web / ' + project.name
    expect(page).to have_content 'Namespace: Web'
  end

  step 'I visit project "Enterprise" members page' do
    project = Project.find_by!(name: "Enterprise")
    visit namespace_project_project_members_path(project.namespace, project)
  end

  step 'I select current user as "Developer"' do
    page.within ".users-project-form" do
      select2(current_user.id, from: "#user_ids", multiple: true)
      select "Developer", from: "access_level"
    end

    click_button "Add users to project"
  end

  step 'I should see current user as "Developer"' do
    page.within '.content-list' do
      expect(page).to have_content(current_user.name)
      expect(page).to have_content('Developer')
    end
  end

  step 'current user is developer of project "Enterprise"' do
    project = Project.find_by!(name: "Enterprise")
    project.team << [current_user, :developer]
  end

  step 'I click on the "Remove User From Project" button for current user' do
    find(:css, 'li', text: current_user.name).find(:css, 'a.btn-remove').click
    # poltergeist always confirms popups.
  end

  step 'I should not see current_user as "Developer"' do
    expect(page).not_to have_selector(:css, '.content-list')
  end

  def project
    @project ||= Project.first
  end

  def group
    Group.find_by(name: 'Web')
  end
end
