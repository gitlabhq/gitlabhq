class Spinach::Features::AdminAppearance < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths

  step 'submit form with new appearance' do
    fill_in 'appearance_title', with: 'MyCompany'
    fill_in 'appearance_description', with: 'dev server'
    click_button 'Save'
  end

  step 'I should be redirected to admin appearance page' do
    current_path.should == admin_appearances_path
    page.should have_content 'Appearance settings'
  end

  step 'I should see newly created appearance' do
    page.should have_field('appearance_title', with: 'MyCompany')
    page.should have_field('appearance_description', with: 'dev server')
    page.should have_content 'Last edit'
  end

  step 'I click preview button' do
    click_link "Preview"
  end

  step 'application has custom appearance' do
    create(:appearance)
  end

  step 'I should see a customized appearance' do
    page.should have_content appearance.title
    page.should have_content appearance.description
  end

  step 'I attach a logo' do
    attach_file(:appearance_logo, File.join(Rails.root, 'public', 'gitlab_logo.png'))
    click_button 'Save'
  end

  step 'I should see a logo' do
    page.should have_xpath('//img[@src="/uploads/appearance/logo/1/gitlab_logo.png"]')
  end

  step 'I remove the logo' do
    click_link 'Remove logo'
  end

  step 'I should see logo removed' do
    page.should_not have_xpath('//img[@src="/uploads/appearance/logo/1/gitlab_logo.png"]')
  end

  def appearance
    Appearance.last
  end
end
