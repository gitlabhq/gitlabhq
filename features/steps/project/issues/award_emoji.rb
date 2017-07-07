class Spinach::Features::AwardEmoji < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths
  include Select2Helper

  step 'I visit "Bugfix" issue page' do
    visit project_issue_path(@project, @issue)
  end

  step 'I click the thumbsup award Emoji' do
    page.within '.awards' do
      thumbsup = page.first('.award-control')
      thumbsup.click
      thumbsup.hover
    end
  end

  step 'I click to emoji-picker' do
    page.within '.awards' do
      page.find('.js-add-award').click
    end
  end

  step 'I click to emoji in the picker' do
    page.within '.emoji-menu-content' do
      emoji_button = page.first('.js-emoji-btn')
      emoji_button.hover
      emoji_button.click
    end
  end

  step 'I can remove it by clicking to icon' do
    page.within '.awards' do
      expect do
        page.find('.js-emoji-btn.active').click
        wait_for_requests
      end.to change { page.all(".award-control.js-emoji-btn").size }.from(3).to(2)
    end
  end

  step 'I can see the activity and food categories' do
    page.within '.emoji-menu' do
      expect(page).not_to have_selector 'Activity'
      expect(page).not_to have_selector 'Food'
    end
  end

  step 'I have new comment with emoji added' do
    expect(page).to have_selector 'gl-emoji[data-name="smile"]'
  end

  step 'I have award added' do
    page.within '.awards' do
      expect(page).to have_selector '.js-emoji-btn'
      expect(page.find('.js-emoji-btn.active .js-counter')).to have_content '1'
      expect(page).to have_css(".js-emoji-btn.active[data-original-title='You']")
    end
  end

  step 'I have no awards added' do
    page.within '.awards' do
      expect(page).to have_selector '.award-control.js-emoji-btn'
      expect(page.all('.award-control.js-emoji-btn').size).to eq(2)

      # Check tooltip data
      page.all('.award-control.js-emoji-btn').each do |element|
        expect(element['title']).to eq("")
      end

      page.all('.award-control .js-counter').each do |element|
        expect(element).to have_content '0'
      end
    end
  end

  step 'project "Shop" has issue "Bugfix"' do
    @project = Project.find_by(name: 'Shop')
    @issue = create(:issue, title: 'Bugfix', project: project)
  end

  step 'I leave comment with a single emoji' do
    page.within('.js-main-target-form') do
      fill_in 'note[note]', with: ':smile:'
      click_button 'Comment'
    end
  end

  step 'I search "hand"' do
    fill_in 'emoji-menu-search', with: 'hand'
  end

  step 'I see search result for "hand"' do
    page.within '.emoji-menu-content' do
      expect(page).to have_selector '[data-name="raised_hand"]'
    end
  end

  step 'The emoji menu is visible' do
    page.find(".emoji-menu.is-visible")
  end

  step 'The search field is focused' do
    expect(page).to have_selector('.js-emoji-menu-search')
    expect(page.evaluate_script("document.activeElement.classList.contains('js-emoji-menu-search')")).to eq(true)
  end
end
