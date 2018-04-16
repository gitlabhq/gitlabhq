class Spinach::Features::ProjectCommitsBranches < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  step 'I click link "All"' do
    click_link "All"
  end

  step 'I click link "Protected"' do
    click_link "Protected"
  end

  step 'I click new branch link' do
    click_link "New branch"
  end

  step 'I submit new branch form with invalid name' do
    fill_in 'branch_name', with: '1.0 stable'
    page.find("body").click # defocus the branch_name input
    select_branch('master')
    click_button 'Create branch'
  end

  def select_branch(branch_name)
    find('.git-revision-dropdown-toggle').click

    page.within '#new-branch-form .dropdown-menu' do
      click_link branch_name
    end
  end
end
