module SharedProject
  include Spinach::DSL

  # Create a project without caring about what it's called
  step "I own a project" do
    @project = create(:project, namespace: @user.namespace)
    @project.team << [@user, :master]
  end

  # Create a specific project called "Shop"
  step 'I own project "Shop"' do
    @project = Project.find_by(name: "Shop")
    @project ||= create(:project, name: "Shop", namespace: @user.namespace, snippets_enabled: true)
    @project.team << [@user, :master]
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
    @project = Project.find_by(name: "Forum")
    @project ||= create(:project, name: "Forum", namespace: @user.namespace, path: 'forum_project')
    @project.team << [@user, :master]
  end

  # Create an empty project without caring about the name
  step 'I own an empty project' do
    @project = create(:empty_project,
                      name: 'Empty Project', namespace: @user.namespace)
    @project.team << [@user, :master]
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

    data = {
      before: Gitlab::Git::BLANK_SHA,
      after: "6d394385cf567f80a8fd85055db1ab4c5295806f",
      ref: "refs/heads/fix",
      user_id: @user.id,
      user_name: @user.name,
      repository: {
        name: @project.name,
        url: "localhost/rubinius",
        description: "",
        homepage: "localhost/rubinius",
        private: true
      }
    }

    @event = Event.create(
      project: @project,
      action: Event::PUSHED,
      data: data,
      author_id: @user.id
    )
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
    user = user_exists("John Doe", username: "john_doe")
    project = Project.find_by(name: "Enterprise")
    project ||= create(:empty_project, name: "Enterprise", namespace: user.namespace)
    project.team << [user, :master]
  end

  step '"John Doe" owns internal project "Internal"' do
    user = user_exists("John Doe", username: "john_doe")
    project = Project.find_by(name: "Internal")
    project ||= create :empty_project, :internal, name: 'Internal', namespace: user.namespace
    project.team << [user, :master]
  end

  step '"John Doe" owns public project "Community"' do
    user = user_exists("John Doe", username: "john_doe")
    project = Project.find_by(name: "Community")
    project ||= create :empty_project, :public, name: 'Community', namespace: user.namespace
    project.team << [user, :master]
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
    create :ci_commit, gl_project: project, sha: project.commit.sha
  end

  step 'I should see last commit with CI status' do
    page.within ".project-last-commit" do
      expect(page).to have_content(project.commit.sha[0..6])
      expect(page).to have_content("skipped")
    end
  end
end
