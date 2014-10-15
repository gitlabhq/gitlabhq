class Spinach::Features::SnippetsDiscover < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedSnippet

  step 'I should see "Personal snippet one" in snippets' do
    page.should have_content "Personal snippet one"
  end

  step 'I should see "Personal snippet internal" in snippets' do
    page.should have_content "Personal snippet internal"
  end

  step 'I should not see "Personal snippet private" in snippets' do
    page.should_not have_content "Personal snippet private"
  end

  def snippet
    @snippet ||= PersonalSnippet.find_by!(title: "Personal snippet one")
  end
end
