require_relative 'user'

module SharedProject
  include Spinach::DSL
  include SharedUser

  # Create a project without caring about what it's called
  step "I own a project" do
    @project = user_owns_project(
      user: @user,
      project_name: 'Internal',
      project_type: :project,
      visibility: :internal
    )
  end

  step "project exists in some group namespace" do
    @group = create(:group, name: 'some group')
    @project = create(:project, namespace: @group)
  end

  # Create a specific project called "Shop"
  step 'I own project "Shop"' do
    @project = user_owns_project(
      user: @user,
      project_name: 'Shop',
      project_type: :project,
      visibility: :internal,
      snippets_enabled: true
    )
  end

  step 'I disable snippets in project' do
    @project.snippets_enabled = false
    @project.save
  end

  step 'I disable issues and merge requests in project' do
    @project.issues_enabled = false
    @project.merge_requests_enabled = false
    @project.save
  end

  # Add another user to project "Shop"
  step 'I add a user to project "Shop"' do
    @project = Project.find_by(name: "Shop")
    other_user = create(:user, name: 'Alpha')
    @project.team << [other_user, :master]
  end

  # Create another specific project called "Forum"
  step 'I own project "Forum"' do
    @project = user_owns_project(
      user: @user,
      project_name: 'Forum',
      project_type: :project,
      path: 'forum_project'
    )
  end

  # Create another specific project called "Forum"
  step 'I own project "Grocery"' do
    @project = user_owns_project(
      user: @user,
      project_name: 'Grocery'
    )
  end

  # Create an empty project without caring about the name
  step 'I own an empty project' do
    @project = user_owns_project(
      user: @user,
      project_name: 'Empty Project'
    )
  end

  step 'I visit my empty project page' do
    project = Project.find_by(name: 'Empty Project')
    visit namespace_project_path(project.namespace, project)
  end

  step 'I visit project "Shop" activity page' do
    project = Project.find_by(name: 'Shop')
    visit namespace_project_path(project.namespace, project)
  end

  step 'project "Shop" has push event' do
    @project = Project.find_by(name: "Shop")
    event_for_project(@project)
  end

  step 'project "Grocery" has push event' do
    @project = Project.find_by(name: "Grocery")
    event_for_project(@project)
  end

  step 'project "Community" has push event' do
    @project = Project.find_by(name: "Community")
    event_for_project(@project)
  end

  step 'I should see project "Shop" activity feed' do
    project = Project.find_by(name: "Shop")
    expect(page).to have_content "#{@user.name} pushed new branch fix at #{project.name_with_namespace}"
  end

  step 'I should see project settings' do
    expect(current_path).to eq edit_namespace_project_path(@project.namespace, @project)
    expect(page).to have_content("Project name")
    expect(page).to have_content("Features:")
  end

  def current_project
    @project ||= Project.first
  end

  # ----------------------------------------
  # Project permissions
  # ----------------------------------------

  step 'I am member of a project with a guest role' do
    @project.team << [@user, Gitlab::Access::GUEST]
  end

  step 'I am member of a project "Community" with a guest role' do
    Project.find_by(name: "Community").team << [@user, Gitlab::Access::GUEST]
  end

  step 'I am member of a project with a reporter role' do
    @project.team << [@user, Gitlab::Access::REPORTER]
  end

  # ----------------------------------------
  # Visibility of archived project
  # ----------------------------------------

  step 'archived project "Archive"' do
    create :project, :public, archived: true, name: 'Archive'
  end

  step 'I should not see project "Archive"' do
    project = Project.find_by(name: "Archive")
    expect(page).not_to have_content project.name_with_namespace
  end

  step 'I should see project "Archive"' do
    project = Project.find_by(name: "Archive")
    expect(page).to have_content project.name_with_namespace
  end

  step 'project "Archive" has comments' do
    project = Project.find_by(name: "Archive")
    2.times { create(:note_on_issue, project: project) }
  end

  # ----------------------------------------
  # Visibility level
  # ----------------------------------------

  step 'private project "Enterprise"' do
    create :project, name: 'Enterprise'
  end

  step 'I should see project "Enterprise"' do
    expect(page).to have_content "Enterprise"
  end

  step 'I should not see project "Enterprise"' do
    expect(page).not_to have_content "Enterprise"
  end

  step 'internal project "Internal"' do
    create :project, :internal, name: 'Internal'
  end

  step 'I should see project "Internal"' do
    expect(page).to have_content "Internal"
  end

  step 'I should not see project "Internal"' do
    expect(page).not_to have_content "Internal"
  end

  step 'public project "Community"' do
    create :project, :public, name: 'Community'
  end

  step 'I should see project "Community"' do
    expect(page).to have_content "Community"
  end

  step 'I should not see project "Community"' do
    expect(page).not_to have_content "Community"
  end

  step '"John Doe" owns private project "Enterprise"' do
    user_owns_project(
      user_name: 'John Doe',
      project_name: 'Enterprise'
    )
  end

  step '"Mary Jane" owns private project "Enterprise"' do
    user_owns_project(
      user_name: 'Mary Jane',
      project_name: 'Enterprise'
    )
  end

  step '"John Doe" owns internal project "Internal"' do
    user_owns_project(
      user_name: 'John Doe',
      project_name: 'Internal',
      visibility: :internal
    )
  end

  step '"John Doe" owns public project "Community"' do
    user_owns_project(
      user_name: 'John Doe',
      project_name: 'Community',
      visibility: :public
    )
  end

  step 'public empty project "Empty Public Project"' do
    create :project_empty_repo, :public, name: "Empty Public Project"
  end

  step 'project "Community" has comments' do
    project = Project.find_by(name: "Community")
    2.times { create(:note_on_issue, project: project) }
  end

  step 'project "Shop" has labels: "bug", "feature", "enhancement"' do
    project = Project.find_by(name: "Shop")
    create(:label, project: project, title: 'bug')
    create(:label, project: project, title: 'feature')
    create(:label, project: project, title: 'enhancement')
  end

  step 'project "Shop" has CI enabled' do
    project = Project.find_by(name: "Shop")
    project.enable_ci
  end

  step 'project "Shop" has CI build' do
    project = Project.find_by(name: "Shop")
    create :ci_commit, project: project, sha: project.commit.sha
  end

  step 'I should see last commit with CI status' do
    page.within ".project-last-commit" do
      expect(page).to have_content(project.commit.sha[0..6])
      expect(page).to have_content("skipped")
    end
  end

  # ----------------------------------------
  # Starring
  # ----------------------------------------

  step 'I starred project "Community"' do
    current_user.toggle_star(Project.find_by(name: 'Community'))
  end

  step 'I starred project "Forum"' do
    current_user.toggle_star(Project.find_by(name: 'Forum'))
  end

  step 'I starred project "Grocery"' do
    current_user.toggle_star(Project.find_by(name: 'Grocery'))
  end

  step '"John Doe" someone starred project "Community"' do
    user_exists("John Doe").toggle_star(Project.find_by(name: 'Community'))
  end

  step '"John Doe" someone starred project "Forum"' do
    user_exists("John Doe").toggle_star(Project.find_by(name: 'Community'))
  end

  # ----------------------------------------
  # Sorting
  # ----------------------------------------

  step 'I sort projects list by "Recently active"' do
    sort_by('Recently active')
  end

  step 'I sort projects list by "Most stars"' do
    sort_by('Most stars')
  end

  step 'I sort projects list by "Name from A to Z"' do
    sort_by('Name from A to Z')
  end

  step 'I sort projects list by "Name from Z to A"' do
    sort_by('Name from Z to A')
  end

  step 'I should see "Community" at the top' do
    expect_top_project_in_list("Community")
  end

  step 'I should see "Shop" at the top' do
    expect_top_project_in_list("Shop")
  end

  step 'I should see "Forum" at the top' do
    expect_top_project_in_list("Forum")
  end

  step 'I should see "Grocery" at the top' do
    expect_top_project_in_list("Grocery")
  end

  # ----------------------------------------
  # Filtering
  # ----------------------------------------

  step 'I filter to see only my own projects' do
    filter_by('Owned by me')
  end

  # ----------------------------------------
  # Links
  # ----------------------------------------

  step 'I should see "New Project" link' do
    expect(page).to have_link "New project"
  end

  step 'I should see "Community" project link' do
    expect_link_in_list "Community"
  end

  step 'I should not see "Community" project link' do
    expect_link_in_list "Community", false
  end

  step 'I should see "Shop" project link' do
    expect_link_in_list "Shop"
  end

  step 'I should not see "Shop" project link' do
    expect_link_in_list "Shop", false
  end

  step 'I should see "Forum" project link' do
    expect_link_in_list "Forum"
  end

  step 'I should see "Grocery" project link' do
    expect_link_in_list "Grocery"
  end

  step 'I should see "Shop" project CI status' do
    expect_link_in_list "Build skipped"
  end

  private

  def event_for_project(project, user)
    data = {
      before: Gitlab::Git::BLANK_SHA,
      after: "6d394385cf567f80a8fd85055db1ab4c5295806f",
      ref: "refs/heads/fix",
      user_id: (user || @user).id,
      user_name: (user || @user).name,
      repository: {
        name: project.name,
        url: "localhost/rubinius",
        description: "",
        homepage: "localhost/rubinius",
        private: true
      }
    }

    @event = Event.create(
      project: project,
      action: Event::PUSHED,
      data: data,
      author_id: (user || @user).id
    )
  end

  def sort_by(sort)
    find('button.dropdown-toggle.btn').click
    page.within('ul.dropdown-menu') do
      click_link sort
    end
  end

  def filter_by(filter)
    find('button.dropdown-toggle.btn').click
    page.within('ul.dropdown-menu') do
      click_link filter
    end
  end

  def expect_top_project_in_list(project_name)
    expect(page.find('ul.projects-list li.project-row:first-child')).to have_content(project_name)
  end

  def expect_link_in_list(project_name, truthy = true)
    expect(page.find('ul.projects-list')).send (truthy ? 'to' : 'not_to'), have_content(project_name)
  end

  def user_owns_project(user:, project_name: nil, project_type: :empty_project, visibility: :private, **args)
    user = user.is_a?(User) ? user : user_exists(user, username: user.gsub(/\s/, '').underscore)
    project = Project.find_by(name: project_name)
    project ||= create(project_type, visibility, name: project_name, namespace: user.namespace, **args)
    project.team << [user, :master]
  end
end
