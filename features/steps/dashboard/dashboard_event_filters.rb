class EventFilters < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths 
  include SharedProject

  Then 'I should see push event' do
    page.find('span.pushed').should have_content('pushed')
  end

  Then 'I should see new member event' do
    page.find('span.joined').should have_content('joined')
  end

  Then 'I should see merge request event' do
    page.find('span.merged').should have_content('merged')
  end

  And 'this project has push event' do
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

  And 'this project has new member event' do
    user = create(:user, {name: "John Doe"})
    Event.create(
      project: @project,
      author_id: user.id,
      action: Event::Joined
    )
  end

  And 'this project has merge request event' do
    merge_request = create :merge_request, author: @user, project: @project
    Event.create(
      project: @project,
      action: Event::Merged,
      target_id: merge_request.id,
      target_type: "MergeRequest",
      author_id: @user.id
    )    
  end

end

