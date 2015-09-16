class Spinach::Features::SnippetsUser < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedSnippet

  step 'I visit my snippets page' do
    visit dashboard_snippets_path
  end

  step 'I should see "Personal snippet one" in snippets' do
    expect(page).to have_content "Personal snippet one"
  end

  step 'I should see "Personal snippet private" in snippets' do
    expect(page).to have_content "Personal snippet private"
  end

  step 'I should see "Personal snippet internal" in snippets' do
    expect(page).to have_content "Personal snippet internal"
  end

  step 'I should not see "Personal snippet one" in snippets' do
    expect(page).not_to have_content "Personal snippet one"
  end

  step 'I should not see "Personal snippet private" in snippets' do
    expect(page).not_to have_content "Personal snippet private"
  end

  step 'I should not see "Personal snippet internal" in snippets' do
    expect(page).not_to have_content "Personal snippet internal"
  end

  step 'I click "Internal" filter' do
    page.within('.nav-tabs') do
      click_link "Internal"
    end
  end

  step 'I click "Private" filter' do
    page.within('.nav-tabs') do
      click_link "Private"
    end
  end

  step 'I click "Public" filter' do
    page.within('.nav-tabs') do
      click_link "Public"
    end
  end

  def snippet
    @snippet ||= PersonalSnippet.find_by!(title: "Personal snippet one")
  end
end
