class Spinach::Features::ProjectCommitsBranches < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  step 'I click link "All"' do
    click_link "All"
  end

  step 'I should see "Shop" all branches list' do
    expect(page).to have_content "Branches"
    expect(page).to have_content "master"
  end

  step 'I click link "Protected"' do
    click_link "Protected"
  end

  step 'I should see "Shop" protected branches list' do
    page.within ".protected-branches-list" do
      expect(page).to have_content "stable"
      expect(page).not_to have_content "master"
    end
  end

  step 'project "Shop" has protected branches' do
    project = Project.find_by(name: "Shop")
    create(:protected_branch, project: project, name: "stable")
  end

  step 'I click new branch link' do
    click_link "New branch"
  end

  step 'I submit new branch form' do
    fill_in 'branch_name', with: 'deploy_keys'
    select_branch('master')
    click_button 'Create branch'
  end

  step 'I submit new branch form with invalid name' do
    fill_in 'branch_name', with: '1.0 stable'
    select_branch('master')
    click_button 'Create branch'
  end

  step 'I submit new branch form with branch that already exists' do
    fill_in 'branch_name', with: 'master'
    select_branch('master')
    click_button 'Create branch'
  end

  step 'I should see new branch created' do
    expect(page).to have_content 'deploy_keys'
  end

  step 'I should see new an error that branch is invalid' do
    expect(page).to have_content 'Branch name is invalid'
    expect(page).to have_content "can't contain spaces"
  end

  step 'I should see new an error that branch already exists' do
    expect(page).to have_content 'Branch already exists'
  end

  step 'I filter for branch improve/awesome' do
    fill_in 'branch-search', with: 'improve/awesome'
    find('#branch-search').native.send_keys(:enter)
  end

  step "I click branch 'improve/awesome' delete link" do
    page.within '.js-branch-improve\/awesome' do
      find('.btn-remove').click
      sleep 0.05
    end
  end

  step "I should not see branch 'improve/awesome'" do
    expect(page.all(visible: true)).not_to have_content 'improve/awesome'
  end

  def select_branch(branch_name)
    click_button 'master'

    page.within '#new-branch-form .dropdown-menu' do
      click_link branch_name
    end
  end
end
