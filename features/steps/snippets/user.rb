class UserSnippets < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedSnippet

  Given 'I visit my snippets page' do
    visit user_snippets_path(current_user)
  end

  Then 'I should see "Personal snippet one" in snippets' do
    page.should have_content "Personal snippet one"
  end

  And 'I should see "Personal snippet private" in snippets' do
    page.should have_content "Personal snippet private"
  end

  Then 'I should not see "Personal snippet one" in snippets' do
    page.should_not have_content "Personal snippet one"
  end

  And 'I should not see "Personal snippet private" in snippets' do
    page.should_not have_content "Personal snippet private"
  end

  Given 'I click "Public" filter' do
    within('.nav-stacked') do
      click_link "Public"
    end
  end

  Given 'I click "Private" filter' do
    within('.nav-stacked') do
      click_link "Private"
    end
  end

  def snippet
    @snippet ||= PersonalSnippet.find_by!(title: "Personal snippet one")
  end
end
