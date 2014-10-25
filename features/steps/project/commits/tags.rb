class Spinach::Features::ProjectCommitsTags < Spinach::FeatureSteps
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

  step "I delete tag 'v1.1.0'" do
    within '.tags' do
      first('.btn-remove').click
      sleep 0.05
    end
  end

  step "I should not see tag 'v1.1.0'" do
    within '.tags' do
      all(visible: true).should_not have_content 'v1.1.0'
    end
  end

  step 'I delete all tags' do
    within '.tags' do
      all('.btn-remove').each do |remove|
        remove.click
        sleep 0.05
      end
    end
  end

  step 'I should see tags info message' do
    within '.tags' do
      page.should have_content 'Repository has no tags yet.'
    end
  end
end
