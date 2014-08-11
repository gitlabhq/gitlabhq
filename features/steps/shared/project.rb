module SharedProject
  include Spinach::DSL

  # Create a project without caring about what it's called
  And "I own a project" do
    @project = create(:project, namespace: @user.namespace)
    @project.team << [@user, :master]
  end

  # Create a specific project called "Shop"
  And 'I own project "Shop"' do
    @project = Project.find_by(name: "Shop")
    @project ||= create(:project, name: "Shop", namespace: @user.namespace, snippets_enabled: true)
    @project.team << [@user, :master]
  end

  # Create another specific project called "Forum"
  And 'I own project "Forum"' do
    @project = Project.find_by(name: "Forum")
    @project ||= create(:project, name: "Forum", namespace: @user.namespace, path: 'forum_project')
    @project.team << [@user, :master]
  end

  # Create an empty project without caring about the name
  And 'I own an empty project' do
    @project = create(:empty_project,
                      name: 'Empty Project', namespace: @user.namespace)
    @project.team << [@user, :master]
  end

  And 'project "Shop" has push event' do
    @project = Project.find_by(name: "Shop")

    data = {
      before: "0000000000000000000000000000000000000000",
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

  Then 'I should see project "Shop" activity feed' do
    project = Project.find_by(name: "Shop")
    page.should have_content "#{@user.name} pushed new branch fix at #{project.name_with_namespace}"
  end

  Then 'I should see project settings' do
    current_path.should == edit_project_path(@project)
    page.should have_content("Project name")
    page.should have_content("Features:")
  end

  def current_project
    @project ||= Project.first
  end

  # ----------------------------------------
  # Visibility level
  # ----------------------------------------

  step 'private project "Enterprise"' do
    create :project, name: 'Enterprise'
  end

  step 'I should see project "Enterprise"' do
    page.should have_content "Enterprise"
  end

  step 'I should not see project "Enterprise"' do
    page.should_not have_content "Enterprise"
  end

  step 'internal project "Internal"' do
    create :project, :internal, name: 'Internal'
  end

  step 'I should see project "Internal"' do
    page.should have_content "Internal"
  end

  step 'I should not see project "Internal"' do
    page.should_not have_content "Internal"
  end

  step 'public project "Community"' do
    create :project, :public, name: 'Community'
  end

  step 'I should see project "Community"' do
    page.should have_content "Community"
  end

  step 'I should not see project "Community"' do
    page.should_not have_content "Community"
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
    create :empty_project, :public, name: "Empty Public Project"
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
end
