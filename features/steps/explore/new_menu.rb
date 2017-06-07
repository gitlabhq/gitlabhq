class Spinach::Features::NewMenu < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject

  step 'I click "New project" in top right menu' do
    click_topmenuitem("New project")
  end

  step 'I click "New group" in top right menu' do
    click_topmenuitem("New group")
  end

  step 'I click "New snippet" in top right menu' do
    click_topmenuitem("New snippet")
  end

  step 'I click "New project snippet" in top right menu' do
    page.within '.header-content' do
      find('.header-new-dropdown-toggle').trigger('click')
      expect(page).to have_selector('.header-new.dropdown.open', count: 1)
      find('.header-new-project-snippet a').trigger('click')
    end
  end

  step 'I click "New issue" in top right menu' do
    click_topmenuitem("New issue")
  end

  step 'I click "New merge request" in top right menu' do
    click_topmenuitem("New merge request")
  end

  step 'I click "New subgroup" in top right menu' do
    click_topmenuitem("New subgroup")
  end

  step 'I click "New group project" in top right menu' do
    page.within '.header-content' do
      find('.header-new-dropdown-toggle').trigger('click')
      expect(page).to have_selector('.header-new.dropdown.open', count: 1)
      find('.header-new-group-project a').trigger('click')
    end
  end

  step 'I see "New Project" page' do
    expect(page).to have_content('Project path')
    expect(page).to have_content('Project name')
  end

  step 'I see "New Group" page' do
    expect(page).to have_content('Group path')
    expect(page).to have_content('Group name')
  end

  step 'I see "New Snippet" page' do
    expect(page).to have_content('New Snippet')
    expect(page).to have_content('Title')
  end

  step 'I see "New Issue" page' do
    expect(page).to have_content('New Issue')
    expect(page).to have_content('Title')
  end

  step 'I see "New Merge Request" page' do
    expect(page).to have_content('New Merge Request')
    expect(page).to have_content('Source branch')
    expect(page).to have_content('Target branch')
  end

  def click_topmenuitem(item_name)
    page.within '.header-content' do
      find('.header-new-dropdown-toggle').trigger('click')
      expect(page).to have_selector('.header-new.dropdown.open', count: 1)
      click_link item_name
    end
  end
end
