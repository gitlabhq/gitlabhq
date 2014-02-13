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
    @project ||= create(:project, name: "Shop", namespace: @user.namespace)
    @project.team << [@user, :master]
  end

  # Create another specific project called "Forum"
  And 'I own project "Forum"' do
    @project = Project.find_by(name: "Forum")
    @project ||= create(:project, name: "Forum", namespace: @user.namespace, path: 'forum_project')
    @project.team << [@user, :master]
  end

  And 'project "Shop" has push event' do
    @project = Project.find_by(name: "Shop")

    data = {
      before: "0000000000000000000000000000000000000000",
      after: "0220c11b9a3e6c69dc8fd35321254ca9a7b98f7e",
      ref: "refs/heads/new_design",
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
    page.should have_content "#{@user.name} pushed new branch new_design at #{project.name_with_namespace}"
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
    create :project, name: 'Internal', visibility_level: Gitlab::VisibilityLevel::INTERNAL
  end

  step 'I should see project "Internal"' do
    page.should have_content "Internal"
  end

  step 'I should not see project "Internal"' do
    page.should_not have_content "Internal"
  end

  step 'public project "Community"' do
    create :project, name: 'Community', visibility_level: Gitlab::VisibilityLevel::PUBLIC
  end

  step 'I should see project "Community"' do
    page.should have_content "Community"
  end

  step 'I should not see project "Community"' do
    page.should_not have_content "Community"
  end

  step '"John Doe" is authorized to private project "Enterprise"' do
    user = user_exists("John Doe", username: "john_doe")
    project = Project.find_by(name: "Enterprise")
    project ||= create(:project, name: "Enterprise", namespace: user.namespace)
    project.team << [user, :master]
  end

  step '"John Doe" is authorized to internal project "Internal"' do
    user = user_exists("John Doe", username: "john_doe")
    project = Project.find_by(name: "Internal")
    project ||= create :project, name: 'Internal', visibility_level: Gitlab::VisibilityLevel::INTERNAL
    project.team << [user, :master]
  end

  step '"John Doe" is authorized to public project "Community"' do
    user = user_exists("John Doe", username: "john_doe")
    project = Project.find_by(name: "Community")
    project ||= create :project, name: 'Community', visibility_level: Gitlab::VisibilityLevel::PUBLIC
    project.team << [user, :master]
  end
end
