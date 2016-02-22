class Spinach::Features::RevertCommits < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths
  include SharedDiffNote
  include RepoHelpers

  step 'I click on commit link' do
    visit namespace_project_commit_path(@project.namespace, @project, sample_commit.id)
  end

  step 'I click on the revert button' do
    find("a[href='#modal-revert-commit']").click
  end

  step 'I revert the changes directly' do
    page.within('#modal-revert-commit') do
      uncheck 'create_merge_request'
      click_button 'Revert'
    end
  end

  step 'I should see the revert commit notice' do
    page.should have_content('The commit has been successfully reverted.')
  end

  step 'I should see a revert error' do
    page.should have_content('Sorry, we cannot revert this commit automatically.')
  end

  step 'I revert the changes in a new merge request' do
    page.within('#modal-revert-commit') do
      click_button 'Revert'
    end
  end

  step 'I should see the new merge request notice' do
    page.should have_content('The commit has been successfully reverted. You can now submit a merge request to get this change into the original branch.')
  end
end
