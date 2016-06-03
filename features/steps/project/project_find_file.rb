class Spinach::Features::ProjectFindFile < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject
  include SharedProjectTab

  step 'I press "t"' do
    find('body').native.send_key('t')
  end

  step 'I click Find File button' do
    click_link 'Find File'
  end

  step 'I should see "find file" page' do
    ensure_active_main_tab('Files')
    expect(page).to have_selector('.file-finder-holder', count: 1)
  end

  step 'I fill in Find by path with "git"' do
    ensure_active_main_tab('Files')
    expect(page).to have_selector('.file-finder-holder', count: 1)
  end

  step 'I fill in file find with "git"' do
    find_file "git"
  end

  step 'I fill in file find with "change"' do
    find_file "change"
  end

  step 'I fill in file find with "asdfghjklqwertyuizxcvbnm"' do
    find_file "asdfghjklqwertyuizxcvbnm"
  end

  step 'I should see "VERSION" in files' do
    expect(page).to have_content("VERSION")
  end

  step 'I should not see "VERSION" in files' do
    expect(page).not_to have_content("VERSION")
  end

  step 'I should see "CHANGELOG" in files' do
    expect(page).to have_content("CHANGELOG")
  end

  step 'I should not see "CHANGELOG" in files' do
    expect(page).not_to have_content("CHANGELOG")
  end

  step 'I should see ".gitmodules" in files' do
    expect(page).to have_content(".gitmodules")
  end

  step 'I should not see ".gitmodules" in files' do
    expect(page).not_to have_content(".gitmodules")
  end

  step 'I should see ".gitignore" in files' do
    expect(page).to have_content(".gitignore")
  end

  step 'I should not see ".gitignore" in files' do
    expect(page).not_to have_content(".gitignore")
  end


  def find_file(text)
    fill_in 'file_find', with: text
  end
end
