module SharedProject
  include Spinach::DSL

  # Create a project without caring about what it's called
  And "I own a project" do
    @project = create(:project_with_code, namespace: @user.namespace)
    @project.team << [@user, :master]
  end

  # Create a specific project called "Shop"
  And 'I own project "Shop"' do
    @project = Project.find_by_name "Shop"
    @project ||= create(:project_with_code, name: "Shop", namespace: @user.namespace)
    @project.team << [@user, :master]
  end

  # Create another specific project called "Forum"
  And 'I own project "Forum"' do
    @project = Project.find_by_name "Forum"
    @project ||= create(:project_with_code, name: "Forum", namespace: @user.namespace, path: 'forum_project')
    @project.team << [@user, :master]
  end

  And 'project "Shop" has push event' do
    @project = Project.find_by_name("Shop")

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
    project = Project.find_by_name("Shop")
    page.should have_content "#{@user.name} pushed new branch new_design at #{project.name_with_namespace}"
  end

  Then 'I should see project settings' do
    current_path.should == edit_project_path(@project)
    page.should have_content("Project name")
    page.should have_content("Features:")
  end

  Then 'page status code should be 404' do
    page.status_code.should == 404
  end

  def current_project
    @project ||= Project.first
  end
end
