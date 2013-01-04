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

  def current_project
    @project ||= Project.first
  end
end
