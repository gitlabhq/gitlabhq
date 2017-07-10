class Spinach::Features::RevertMergeRequests < Spinach::FeatureSteps
  include LoginHelpers
  include WaitForRequests

  step 'I click on the revert button' do
    find("a[href='#modal-revert-commit']").click
  end

  step 'I revert the changes directly' do
    page.within('#modal-revert-commit') do
      uncheck 'create_merge_request'
      click_button 'Revert'
    end
  end

  step 'I should see the revert merge request notice' do
    page.should have_content('The merge request has been successfully reverted.')
    wait_for_requests
  end

  step 'I should not see the revert button' do
    expect(page).not_to have_selector(:xpath, "a[href='#modal-revert-commit']")
  end

  step 'I am on the Merge Request detail page' do
    visit merge_request_path(@merge_request)
  end

  step 'I click on Accept Merge Request' do
    click_button('Merge')
  end

  step 'I am signed in as a developer of the project' do
    @user = create(:user) { |u| @project.add_developer(u) }
    sign_in(@user)
  end

  step 'There is an open Merge Request' do
    @merge_request = create(:merge_request, :with_diffs, :simple)
    @project = @merge_request.source_project
  end

  step 'I should see a revert error' do
    page.should have_content('Sorry, we cannot revert this merge request automatically.')
  end

  step 'I revert the changes in a new merge request' do
    page.within('#modal-revert-commit') do
      click_button 'Revert'
    end
  end

  step 'I should see the new merge request notice' do
    page.should have_content('The merge request has been successfully reverted. You can now submit a merge request to get this change into the original branch.')
  end
end
