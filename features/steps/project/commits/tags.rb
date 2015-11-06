class Spinach::Features::ProjectCommitsTags < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  step 'I should see "Shop" all tags list' do
    expect(page).to have_content "Tags"
    expect(page).to have_content "v1.0.0"
  end

  step 'I click new tag link' do
    click_link 'New tag'
  end

  step 'I submit new tag form' do
    fill_in 'tag_name', with: 'v7.0'
    fill_in 'ref', with: 'master'
    click_button 'Create tag'
  end

  step 'I submit new tag form with release notes' do
    fill_in 'tag_name', with: 'v7.0'
    fill_in 'ref', with: 'master'
    fill_in 'release_description', with: 'Awesome release notes'
    click_button 'Create tag'
  end

  step 'I fill release notes and submit form' do
    fill_in 'release_description', with: 'Awesome release notes'
    click_button 'Save changes'
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
    expect(page).to have_content 'v7.0'
  end

  step 'I should see new an error that tag is invalid' do
    expect(page).to have_content 'Tag name invalid'
  end

  step 'I should see new an error that tag ref is invalid' do
    expect(page).to have_content 'Invalid reference name'
  end

  step 'I should see new an error that tag already exists' do
    expect(page).to have_content 'Tag already exists'
  end

  step "I visit tag 'v1.1.0' page" do
    click_link 'v1.1.0'
  end

  step "I delete tag 'v1.1.0'" do
    page.within('.content') do
      first('.btn-remove').click
    end
  end

  step "I should not see tag 'v1.1.0'" do
    page.within '.tags' do
      expect(page).not_to have_link 'v1.1.0'
    end
  end

  step 'I click edit tag link' do
    click_link 'Edit release notes'
  end

  step 'I should see tag release notes' do
    expect(page).to have_content 'Awesome release notes'
  end
end
