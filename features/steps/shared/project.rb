module SharedProject
  include Spinach::DSL

  # Create a project without caring about what it's called
  And "I own a project" do
    @project = create(:project)
    @project.team << [@user, :master]
  end

  # Create a specific project called "Shop"
  And 'I own project "Shop"' do
    @project = create(:project, name: "Shop")
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
      action: Event::Pushed,
      data: data,
      author_id: @user.id
    )
  end

  Then 'I should see project "Shop" activity feed' do
    project = Project.find_by_name("Shop")
    page.should have_content "#{@user.name} pushed new branch new_design at #{project.name}"
  end

  Then 'I should see project settings' do
    current_path.should == edit_project_path(@project)
    page.should have_content("Project name is")
    page.should have_content("Features:")
  end

  def current_project
    @project ||= Project.first
  end
end
