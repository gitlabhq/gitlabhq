module SharedProject
  include Spinach::DSL

  # Create a project without caring about what it's called
  step "I own a project" do
    @project = create(:project, :repository, namespace: @user.namespace)
    @project.add_master(@user)
  end

  step "I own a project in some group namespace" do
    @group = create(:group, name: 'some group')
    @project = create(:project, namespace: @group)
    @project.add_master(@user)
  end

  # Create a specific project called "Shop"
  step 'I own project "Shop"' do
    @project = Project.find_by(name: "Shop")
    @project ||= create(:project, :repository, name: "Shop", namespace: @user.namespace)
    @project.add_master(@user)
  end

  def current_project
    @project ||= Project.first
  end

  # ----------------------------------------
  # Visibility of archived project
  # ----------------------------------------

  step 'I should not see project "Archive"' do
    project = Project.find_by(name: "Archive")
    expect(page).not_to have_content project.full_name
  end

  step 'I should see project "Archive"' do
    project = Project.find_by(name: "Archive")
    expect(page).to have_content project.full_name
  end

  # ----------------------------------------
  # Visibility level
  # ----------------------------------------

  step 'private project "Enterprise"' do
    create(:project, :private, :repository, name: 'Enterprise')
  end

  step 'I should see project "Enterprise"' do
    expect(page).to have_content "Enterprise"
  end

  step 'I should not see project "Enterprise"' do
    expect(page).not_to have_content "Enterprise"
  end

  step 'internal project "Internal"' do
    create(:project, :internal, :repository, name: 'Internal')
  end

  step 'I should see project "Internal"' do
    page.within '.js-projects-list-holder' do
      expect(page).to have_content "Internal"
    end
  end

  step 'I should not see project "Internal"' do
    page.within '.js-projects-list-holder' do
      expect(page).not_to have_content "Internal"
    end
  end

  step 'public project "Community"' do
    create(:project, :public, :repository, name: 'Community')
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

  step 'project "Shop" has labels: "bug", "feature", "enhancement"' do
    project = Project.find_by(name: "Shop")
    create(:label, project: project, title: 'bug')
    create(:label, project: project, title: 'feature')
    create(:label, project: project, title: 'enhancement')
  end

  def user_owns_project(user_name:, project_name:, visibility: :private)
    user = user_exists(user_name, username: user_name.gsub(/\s/, '').underscore)
    project = Project.find_by(name: project_name)
    project ||= create(:project, visibility, name: project_name, namespace: user.namespace)
    project.add_master(user)
  end
end
