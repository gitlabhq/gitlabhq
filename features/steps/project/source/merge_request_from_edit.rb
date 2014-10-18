class Spinach::Features::ProjectSourceMergeRequestFromEdit < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedProjectSource
  include SharedPaths

  step 'I check "Create merge request"' do
    check :create_merge_request
  end

  step 'I check "On my fork"' do
    check :on_my_fork
  end

  step 'I uncheck "On my fork"' do
    uncheck :on_my_fork
  end

  step 'I fill the new branch name' do
    fill_in :new_branch_name, with: valid_new_branch_name
  end

  step 'I fill the new branch name with a non-default value' do
    fill_in :new_branch_name, with: non_default_branch_name
  end

  step 'The new branch name is the non-default value' do
    expect(page).to have_field(:new_branch_name, with: non_default_branch_name)
  end

  step 'I fill the new branch name with an invalid branch name' do
    fill_in :new_branch_name, with: invalid_branch_name
  end

  step 'I should be redirected to the new merge request page from origin to itself' do
    page.should have_content(
      "From #{@project.namespace.path}:#{valid_new_branch_name} "\
      "into #{@project.namespace.path}:#{@project.default_branch}"
    )
  end

  step 'I should be redirected to the new merge request page from origin to fork' do
    page.should have_content(
      "From #{@user.fork_of(@project).namespace.path}:#{valid_new_branch_name} "\
      "into #{@project.namespace.path}:#{@project.default_branch}"
    )
  end

  step 'I should be redirected to the new merge request page from fork to itself' do
    page.should have_content(
      "From #{@user.fork_of(@project).namespace.path}:#{valid_new_branch_name} "\
      "into #{@user.fork_of(@project).namespace.path}:#{@project.default_branch}"
    )
  end

  step 'I see the "New branch name" input' do
    expect(page).to have_field(:new_branch_name)
  end

  step 'I don\'t see the "New branch name" input' do
    expect(page).not_to have_field(:new_branch_name)
  end

  step 'The new branch name is "patch-1"' do
    expect(page).to have_field(:new_branch_name, with: 'patch-1')
  end

  step 'The new branch name is "patch-2"' do
    expect(page).to have_field(:new_branch_name, with: 'patch-2')
  end

  step 'I don\'t see the "On my fork" checkbox' do
    expect(page).not_to have_field(:on_my_fork)
  end

  step '"Create merge request" is checked and disabled' do
    expect(page).to have_field(:create_merge_request,
                               checked: true, disabled: true)
  end

  step '"On my fork" is checked and disabled' do
    expect(page).to have_field(:on_my_fork, checked: true, disabled: true)
  end

  step 'Project "Shop" has a branch named "patch-1"' do
    Project.find_by(name: 'Shop').repository.add_branch('patch-1')
  end

  private

  # A constant value different from any default branch name
  # that can be suggested on the form.
  def non_default_branch_name
    'non-default'
  end
end
