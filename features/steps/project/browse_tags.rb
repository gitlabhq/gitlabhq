class ProjectBrowseTags < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  step 'I should see "Shop" all tags list' do
    page.should have_content "Tags"
    page.should have_content "v1.0.0"
  end

  step 'I click new tag link' do
    click_link 'New tag'
  end

  step 'I submit new tag form' do
    fill_in 'tag_name', with: 'v7.0'
    fill_in 'ref', with: 'master'
    click_button 'Create tag'
  end

  step 'I submit new tag form with invalid name' do
    fill_in 'tag_name', with: 'v 1.0'
    fill_in 'ref', with: 'master'
    click_button 'Create tag'
  end

  step 'I submit new tag form with invalid reference' do
    fill_in 'tag_name', with: 'foo'
    fill_in 'ref', with: 'foo'
    click_button 'Create tag'
  end

  step 'I submit new tag form with tag that already exists' do
    fill_in 'tag_name', with: 'v1.0.0'
    fill_in 'ref', with: 'master'
    click_button 'Create tag'
  end

  step 'I should see new tag created' do
    page.should have_content 'v7.0'
  end

  step 'I should see new an error that tag is invalid' do
    page.should have_content 'Tag name invalid'
  end

  step 'I should see new an error that tag ref is invalid' do
    page.should have_content 'Invalid reference name'
  end

  step 'I should see new an error that tag already exists' do
    page.should have_content 'Tag already exists'
  end
end
