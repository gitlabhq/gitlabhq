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
    @forked_project ||= create(:source_project_with_code, name: "Forked Shop", forked_project_link: forked_project_link, creator_id: @forking_user.id)
    forked_project_link.forked_from_project = @project
    forked_project_link.forked_to_project = @forked_project
    forked_project_link.save!
  end


  Given 'I click link "New Merge Request"' do
    click_link "New Merge Request"
  end


  Then 'I should see merge request "Merge Request On Forked Project"' do
    page.should have_content "Merge Request On Forked Project"
    @project.merge_requests.size.should >= 1
    @merge_request = @project.merge_requests.last
    current_path.should == project_merge_request_path(@project, @merge_request)
    @merge_request.title.should == "Merge Request On Forked Project"
    @merge_request.source_project.should == @forked_project
  end

  And 'I fill out a "Merge Request On Forked Project" merge request' do
    fill_in "merge_request_title", with: "Merge Request On Forked Project"
    find(:select, "merge_request_source_project_id", {}).value.should == @forked_project.id.to_s
    find(:select, "merge_request_target_project_id", {}).value.should == @forked_project.id.to_s

    select @project.path_with_namespace, from: "merge_request_target_project_id"
    find(:select, "merge_request_target_project_id", {}).value.should == @project.id.to_s

    select "master", from: "merge_request_source_branch"
    find(:select, "merge_request_source_branch", {}).value.should == "master"
    select "stable", from: "merge_request_target_branch"
    find(:select, "merge_request_target_branch", {}).value.should == "stable"
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
    find("#merge_request_target_branch").value.should == "master"
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


  Then 'I click link edit "Merge Request On Forked Project"' do
    #there are other edit buttons in this page for replies
#    links = page.all("a.btn.grouped")
#    links.each {|e|puts e.inspect  }
    #TODO:[IA-08] there has got to be a better way to find this button -- there are multiple "Edit" buttons, so that won't work, maybe if we give it an explicit class in the haml
    #click_link "Edit"  # doesn't work, multiple "Edit" buttons
    #    find(:link, "a.btn:nth-child(3)").click
    #    find(:link, "/html/body/div[2]/div/div/h3/span[5]/a[2]").click
    page.first(:xpath, "/html/body/div[2]/div/div/h3/span[5]/a[2]").click
  end

  Then 'I see prefilled "Merge Request On Forked Project"' do
    current_path.should == edit_project_merge_request_path(@project, @merge_request)
    page.should have_content "Edit merge request #{@merge_request.id}"
    find("#merge_request_source_project_id").value.should == @forked_project.id.to_s
    find("#merge_request_target_project_id").value.should == @project.id.to_s
    find("#merge_request_source_branch").value.should == "master"
    find("#merge_request_target_branch").value.should == "stable"
    find("#merge_request_title").value.should == "Merge Request On Forked Project"
  end


  def project
    @project ||= Project.find_by_name!("Shop")
  end

end
