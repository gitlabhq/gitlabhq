module SharedProject
  include Spinach::DSL

  # Create a project without caring about what it's called
  And "I own a project" do
    @project = create(:project)
    @project.add_access(@user, :admin)
  end

  # Create a specific project called "Shop"
  And 'I own project "Shop"' do
    @project = Factory :project, :name => "Shop"
    @project.add_access(@user, :admin)
  end

  def current_project
    @project ||= Project.first
  end
end
