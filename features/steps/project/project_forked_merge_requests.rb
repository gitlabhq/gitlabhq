class ProjectForkedMergeRequests < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedNote
  include SharedPaths


  Given 'I am a member of project "Shop"' do
    @project = Project.find_by_name "Shop"
    @project ||= create(:project_with_code, name: "Shop")
    @project.team << [@user, :reporter]
  end

  And 'I have a project forked off of "Shop" called "Forked Shop"' do
    @forking_user = @user
    forked_project_link = build(:forked_project_link)
    @forked_project = Project.find_by_name "Forked Shop"
    @forked_project ||=  create(:source_project_with_code, name: "Forked Shop", forked_project_link: forked_project_link, creator_id: @forking_user.id)
    forked_project_link.forked_from_project = @project
    forked_project_link.forked_to_project = @forked_project
    forked_project_link.save!
  end


  Given 'I click link "New Merge Request"' do
    click_link "New Merge Request"
  end


  Then 'I should see merge request "Forked Wiki Feature"' do
    page.should have_content "Forked Wiki Feature"
  end

  And 'I fill out a "Forked Wiki Feature" merge request' do
    fill_in "merge_request_title", :with => "Forked Wiki Feature"
    select @forked_project.path_with_namespace, :from => "merge_request_target_project_id"
    select "master", :from => "merge_request_source_branch"
    select "stable", :from => "merge_request_target_branch"
  end

  And 'I submit the merge request' do
    click_button "Submit merge request"
  end

  And 'I follow the target commit link' do
    commit = @project.repository.commit
    click_link commit.short_id(8)
  end

  Then 'I should see the commit under the forked from project' do
    commit = @project.repository.commit
    page.should have_content(commit.message)
  end

  And 'I click "Create Merge Request on fork" link' do
    click_link "Create Merge Request on fork"
  end

  Then 'I see prefilled new Merge Request page for the forked project' do
    current_path.should == new_project_merge_request_path(@forked_project)
    find("#merge_request_source_project_id").value.should == @forked_project.id.to_s
    find("#merge_request_target_project_id").value.should == @project.id.to_s
    find("#merge_request_source_branch").value.should == "new_design"
    find("#merge_request_target_branch").value.should == "Select branch"
    find("#merge_request_title").value.should == "New Design"
  end

  Then 'I should see last push widget' do
    page.should have_content "You pushed to new_design"
    page.should have_link "Create Merge Request"
  end

  Given 'project "Forked Shop" has push event' do
    @forked_project = Project.find_by_name("Forked Shop")

    data = {
        before: "0000000000000000000000000000000000000000",
        after: "0220c11b9a3e6c69dc8fd35321254ca9a7b98f7e",
        ref: "refs/heads/new_design",
        user_id: @user.id,
        user_name: @user.name,
        repository: {
            name: @forked_project.name,
            url: "localhost/rubinius",
            description: "",
            homepage: "localhost/rubinius",
            private: true
        }
    }

    @event = Event.create(
        project: @forked_project,
        action: Event::PUSHED,
        data: data,
        author_id: @user.id
    )
  end

  def project
    @project ||= Project.find_by_name!("Shop")
  end

  def merge_request
    @merge_request ||= MergeRequest.find_by_title!("Bug NS-05")
  end
end
