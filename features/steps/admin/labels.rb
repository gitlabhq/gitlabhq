class Spinach::Features::AdminIssuesLabels < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  step 'I visit \'bug\' label edit page' do
    visit edit_admin_label_path(bug_label)
  end

  step 'I visit admin new label page' do
    visit new_admin_label_path
  end

  step 'I visit admin labels page' do
    visit admin_labels_path
  end

  step 'I remove label \'bug\'' do
    page.within "#label_#{bug_label.id}" do
      click_link 'Remove'
    end
  end

  step 'I have labels: "bug", "feature", "enhancement"' do
    ["bug", "feature", "enhancement"].each do |title|
      Label.create(title: title, template: true)
    end
  end

  step 'I delete all labels' do
    page.within '.labels' do
      page.all('.btn-remove').each do |remove|
        remove.click
        sleep 0.05
      end
    end
  end

  step 'I should see labels help message' do
    page.within '.labels' do
      expect(page).to have_content 'There are no any labels yet'
    end
  end

  step 'I submit new label \'support\'' do
    visit new_admin_label_path
    fill_in 'Title', with: 'support'
    fill_in 'Background Color', with: '#F95610'
    click_button 'Save'
  end

  step 'I submit new label \'bug\'' do
    visit new_admin_label_path
    fill_in 'Title', with: 'bug'
    fill_in 'Background Color', with: '#F95610'
    click_button 'Save'
  end

  step 'I submit new label with invalid color' do
    visit new_admin_label_path
    fill_in 'Title', with: 'support'
    fill_in 'Background Color', with: '#12'
    click_button 'Save'
  end

  step 'I should see label exist error message' do
    page.within '.label-form' do
      expect(page).to have_content 'Title has already been taken'
    end
  end

  step 'I should see label color error message' do
    page.within '.label-form' do
      expect(page).to have_content 'Color is invalid'
    end
  end

  step 'I should see label \'feature\'' do
    page.within '.manage-labels-list' do
      expect(page).to have_content 'feature'
    end
  end

  step 'I should see label \'bug\'' do
    page.within '.manage-labels-list' do
      expect(page).to have_content 'bug'
    end
  end

  step 'I should not see label \'bug\'' do
    page.within '.manage-labels-list' do
      expect(page).not_to have_content 'bug'
    end
  end

  step 'I should see label \'support\'' do
    page.within '.manage-labels-list' do
      expect(page).to have_content 'support'
    end
  end

  step 'I change label \'bug\' to \'fix\'' do
    fill_in 'Title', with: 'fix'
    fill_in 'Background Color', with: '#F15610'
    click_button 'Save'
  end

  step 'I should see label \'fix\'' do
    page.within '.manage-labels-list' do
      expect(page).to have_content 'fix'
    end
  end

  def bug_label
    Label.templates.find_or_create_by(title: 'bug')
  end
end
