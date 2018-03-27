class Spinach::Features::ProjectIssuesLabels < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  step 'I visit \'bug\' label edit page' do
    visit edit_project_label_path(project, bug_label)
  end

  step 'I remove label \'bug\'' do
    page.within "#project_label_#{bug_label.id}" do
      first(:link, 'Delete').click
    end
  end

  step 'I delete all labels' do
    page.within '.labels' do
      page.all('.label-list-item').each do
        first('.remove-row').click
        first(:link, 'Delete label').click
      end
    end
  end

  step 'I should see labels help message' do
    page.within '.labels' do
      expect(page).to have_content 'Generate a default set of labels'
      expect(page).to have_content 'New label'
    end
  end

  step 'I submit new label \'support\'' do
    fill_in 'Title', with: 'support'
    fill_in 'Background color', with: '#F95610'
    click_button 'Create label'
  end

  step 'I submit new label \'bug\'' do
    fill_in 'Title', with: 'bug'
    fill_in 'Background color', with: '#F95610'
    click_button 'Create label'
  end

  step 'I submit new label with invalid color' do
    fill_in 'Title', with: 'support'
    fill_in 'Background color', with: '#12'
    click_button 'Create label'
  end

  step 'I should see label label exist error message' do
    page.within '.label-form' do
      expect(page).to have_content 'Title has already been taken'
    end
  end

  step 'I should see label color error message' do
    page.within '.label-form' do
      expect(page).to have_content 'Color must be a valid color code'
    end
  end

  step 'I should see label \'feature\'' do
    page.within '.other-labels .manage-labels-list' do
      expect(page).to have_content 'feature'
    end
  end

  step 'I should see label \'bug\'' do
    page.within '.other-labels .manage-labels-list' do
      expect(page).to have_content 'bug'
    end
  end

  step 'I should not see label \'bug\'' do
    page.within '.other-labels .manage-labels-list' do
      expect(page).not_to have_content 'bug'
    end
  end

  step 'I should see label \'support\'' do
    page.within '.other-labels .manage-labels-list' do
      expect(page).to have_content 'support'
    end
  end

  step 'I change label \'bug\' to \'fix\'' do
    fill_in 'Title', with: 'fix'
    fill_in 'Background color', with: '#F15610'
    click_button 'Save changes'
  end

  step 'I should see label \'fix\'' do
    page.within '.other-labels .manage-labels-list' do
      expect(page).to have_content 'fix'
    end
  end

  def bug_label
    project.labels.find_or_create_by(title: 'bug')
  end
end
