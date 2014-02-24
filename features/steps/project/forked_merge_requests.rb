class ProjectForkedMergeRequests < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedNote
  include SharedPaths
  include Select2Helper

  step 'I am a member of project "Shop"' do
    @project = Project.find_by(name: "Shop")
    @project ||= create(:project, name: "Shop")
    @project.team << [@user, :reporter]
  end

  step 'I have a project forked off of "Shop" called "Forked Shop"' do
    @forking_user = @user
    forked_project_link = build(:forked_project_link)
    @forked_project = Project.find_by(name: "Forked Shop")
    @forked_project ||= create(:project, name: "Forked Shop", forked_project_link: forked_project_link, creator_id: @forking_user.id , namespace: @forking_user.namespace)

    forked_project_link.forked_from_project = @project
    forked_project_link.forked_to_project = @forked_project
    @forked_project.team << [@forking_user , :master]
    forked_project_link.save!
  end

  step 'I click link "New Merge Request"' do
    click_link "New Merge Request"
  end

  step 'I should see merge request "Merge Request On Forked Project"' do
    @project.merge_requests.size.should >= 1
    @merge_request = @project.merge_requests.last
    current_path.should == project_merge_request_path(@project, @merge_request)
    @merge_request.title.should == "Merge Request On Forked Project"
    @merge_request.source_project.should == @forked_project
    @merge_request.source_branch.should == "master"
    @merge_request.target_branch.should == "stable"
    page.should have_content @forked_project.path_with_namespace
    page.should have_content @project.path_with_namespace
    page.should have_content @merge_request.source_branch
    page.should have_content @merge_request.target_branch
  end

  step 'I fill out a "Merge Request On Forked Project" merge request' do
    select2 @forked_project.id, from: "#merge_request_source_project_id"
    select2 @project.id, from: "#merge_request_target_project_id"

    find(:select, "merge_request_source_project_id", {}).value.should == @forked_project.id.to_s
    find(:select, "merge_request_target_project_id", {}).value.should == @project.id.to_s

    select2 "master", from: "#merge_request_source_branch"
    select2 "stable", from: "#merge_request_target_branch"

    find(:select, "merge_request_source_branch", {}).value.should == 'master'
    find(:select, "merge_request_target_branch", {}).value.should == 'stable'

    fill_in "merge_request_title", with: "Merge Request On Forked Project"
  end

  step 'I submit the merge request' do
    click_button "Submit merge request"
  end

  step 'I follow the target commit link' do
    commit = @project.repository.commit
    click_link commit.short_id(8)
  end

  step 'I should see the commit under the forked from project' do
    commit = @project.repository.commit
    page.should have_content(commit.message)
  end

  step 'I click "Create Merge Request on fork" link' do
    click_link "Create Merge Request on fork"
  end

  step 'I see prefilled new Merge Request page for the forked project' do
    current_path.should == new_project_merge_request_path(@forked_project)
    find("#merge_request_source_project_id").value.should == @forked_project.id.to_s
    find("#merge_request_target_project_id").value.should == @project.id.to_s
    find("#merge_request_source_branch").value.should have_content "new_design"
    find("#merge_request_target_branch").value.should have_content "master"
    find("#merge_request_title").value.should == "New Design"
    verify_commit_link(".mr_target_commit",@project)
    verify_commit_link(".mr_source_commit",@forked_project)
  end

  step 'I update the merge request title' do
    fill_in "merge_request_title", with: "An Edited Forked Merge Request"
  end

  step 'I save the merge request' do
    click_button "Save changes"
  end

  step 'I should see the edited merge request' do
    page.should have_content "An Edited Forked Merge Request"
    @project.merge_requests.size.should >= 1
    @merge_request = @project.merge_requests.last
    current_path.should == project_merge_request_path(@project, @merge_request)
    @merge_request.source_project.should == @forked_project
    @merge_request.source_branch.should == "master"
    @merge_request.target_branch.should == "stable"
    page.should have_content @forked_project.path_with_namespace
    page.should have_content @project.path_with_namespace
    page.should have_content @merge_request.source_branch
    page.should have_content @merge_request.target_branch
  end

  step 'I should see last push widget' do
    page.should have_content "You pushed to new_design"
    page.should have_link "Create Merge Request"
  end

  step 'project "Forked Shop" has push event' do
    @forked_project = Project.find_by(name: "Forked Shop")

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


  step 'I click link edit "Merge Request On Forked Project"' do
    find("#edit_merge_request").click
  end

  step 'I see the edit page prefilled for "Merge Request On Forked Project"' do
    current_path.should == edit_project_merge_request_path(@project, @merge_request)
    page.should have_content "Edit merge request ##{@merge_request.id}"
    find("#merge_request_title").value.should == "Merge Request On Forked Project"
    find("#merge_request_source_project_id").value.should == @forked_project.id.to_s
    find("#merge_request_target_project_id").value.should == @project.id.to_s
    find("#merge_request_source_branch").value.should have_content "master"
    verify_commit_link(".mr_source_commit",@forked_project)
    find("#merge_request_target_branch").value.should have_content "stable"
    verify_commit_link(".mr_target_commit",@project)
  end

  step 'I fill out an invalid "Merge Request On Forked Project" merge request' do
    #If this isn't filled in the rest of the validations won't be triggered
    fill_in "merge_request_title", with: "Merge Request On Forked Project"
    find(:select, "merge_request_source_project_id", {}).value.should == @forked_project.id.to_s
    find(:select, "merge_request_target_project_id", {}).value.should == @forked_project.id.to_s
    find(:select, "merge_request_source_branch", {}).value.should == ""
    find(:select, "merge_request_target_branch", {}).value.should == ""
  end

  step 'I should see validation errors' do
    page.should have_content "Source branch can't be blank"
    page.should have_content "Target branch can't be blank"
    page.should have_content "Branch conflict You can not use same project/branch for source and target"
  end

  def project
    @project ||= Project.find_by!(name: "Shop")
  end

  # Verify a link is generated against the correct project
  def verify_commit_link(container_div, container_project)
    # This should force a wait for the javascript to execute
    find(:div,container_div).find(".commit_short_id")['href'].should have_content "#{container_project.path_with_namespace}/commit"
  end
end
