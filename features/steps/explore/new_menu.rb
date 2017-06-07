class Spinach::Features::NewMenu < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject

  step 'I click "New project" in top right menu' do
    page.within '.header-content' do
      find('.header-new-dropdown-toggle').trigger('click')
      expect(page).to have_selector('.header-new.dropdown.open', count: 1)
      click_link "New project"
    end
  end

  step 'I click "New group" in top right menu' do
    page.within '.header-content' do
      find('.header-new-dropdown-toggle').trigger('click')
      expect(page).to have_selector('.header-new.dropdown.open', count: 1)
      click_link "New group"
    end
  end

  step 'I click "New snippet" in top right menu' do
    page.within '.header-content' do
      find('.header-new-dropdown-toggle').trigger('click')
      expect(page).to have_selector('.header-new.dropdown.open', count: 1)
      click_link "New snippet"
    end
  end

  step 'I click "New issue" in top right menu' do
    page.within '.header-content' do
      find('.header-new-dropdown-toggle').trigger('click')
      expect(page).to have_selector('.header-new.dropdown.open', count: 1)
      click_link "New issue"
    end
  end

  step 'I click "New merge request" in top right menu' do
    page.within '.header-content' do
      find('.header-new-dropdown-toggle').trigger('click')
      expect(page).to have_selector('.header-new.dropdown.open', count: 1)
      click_link "New merge request"
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
end
