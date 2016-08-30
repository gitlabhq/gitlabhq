class Spinach::Features::EventFilters < Spinach::FeatureSteps
  include WaitForAjax
  include SharedAuthentication
  include SharedPaths
  include SharedProject

  step 'I should see push event' do
    expect(page).to have_selector('span.pushed')
  end

  step 'I should not see push event' do
    expect(page).not_to have_selector('span.pushed')
  end

  step 'I should see new member event' do
    expect(page).to have_selector('span.joined')
  end

  step 'I should not see new member event' do
    expect(page).not_to have_selector('span.joined')
  end

  step 'I should see merge request event' do
    expect(page).to have_selector('span.accepted')
  end

  step 'I should not see merge request event' do
    expect(page).not_to have_selector('span.accepted')
  end

  step 'this project has push event' do
    data = {
      before: Gitlab::Git::BLANK_SHA,
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

  step 'this project has new member event' do
    user = create(:user, { name: "John Doe" })
    Event.create(
      project: @project,
      author_id: user.id,
      action: Event::JOINED
    )
  end

  step 'this project has merge request event' do
    merge_request = create :merge_request, author: @user, source_project: @project, target_project: @project
    Event.create(
      project: @project,
      action: Event::MERGED,
      target_id: merge_request.id,
      target_type: "MergeRequest",
      author_id: @user.id
    )
  end

  When 'I click "push" event filter' do
    wait_for_ajax
    click_link("Push events")
    wait_for_ajax
  end

  When 'I click "team" event filter' do
    wait_for_ajax
    click_link("Team")
    wait_for_ajax
  end

  When 'I click "merge" event filter' do
    wait_for_ajax
    click_link("Merge events")
    wait_for_ajax
  end
end
