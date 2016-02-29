class Spinach::Features::AdminAppearance < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths

  step 'submit form with new appearance' do
    fill_in 'appearance_title', with: 'MyCompany'
    fill_in 'appearance_description', with: 'dev server'
    click_button 'Save'
  end

  step 'I should be redirected to admin appearance page' do
    expect(current_path).to eq admin_appearances_path
    expect(page).to have_content 'Appearance settings'
  end

  step 'I should see newly created appearance' do
    expect(page).to have_field('appearance_title', with: 'MyCompany')
    expect(page).to have_field('appearance_description', with: 'dev server')
    expect(page).to have_content 'Last edit'
  end

  step 'I click preview button' do
    click_link "Preview"
  end

  step 'application has custom appearance' do
    create(:appearance)
  end

  step 'I should see a customized appearance' do
    expect(page).to have_content appearance.title
    expect(page).to have_content appearance.description
  end

  step 'I attach a logo' do
    attach_file(:appearance_logo, Rails.root.join('spec', 'fixtures', 'dk.png'))
    click_button 'Save'
  end

  step 'I attach header logos' do
    attach_file(:appearance_header_logo, Rails.root.join('spec', 'fixtures', 'dk.png'))
    click_button 'Save'
  end

  step 'I should see a logo' do
    expect(page).to have_xpath('//img[@src="/uploads/appearance/logo/1/dk.png"]')
  end

  step 'I should see header logos' do
    expect(page).to have_xpath('//img[@src="/uploads/appearance/header_logo/1/dk.png"]')
  end

  step 'I remove the logo' do
    click_link 'Remove logo'
  end

  step 'I remove the header logos' do
    click_link 'Remove header logo'
  end

  step 'I should see logo removed' do
    expect(page).not_to have_xpath('//img[@src="/uploads/appearance/logo/1/gitlab_logo.png"]')
  end

  step 'I should see header logos removed' do
    expect(page).not_to have_xpath('//img[@src="/uploads/appearance/header_logo/1/header_logo_light.png"]')
  end

  def appearance
    Appearance.last
  end
end
