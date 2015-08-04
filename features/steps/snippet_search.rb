class Spinach::Features::SnippetSearch < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedSnippet
  include SharedUser
  include SharedSearch

  step 'I search for "snippet" in snippet titles' do
    search_snippet_titles 'snippet'
  end

  step 'I search for "snippet private" in snippet titles' do
    search_snippet_titles 'snippet private'
  end

  step 'I search for "line seven" in snippet contents' do
    search_snippet_contents 'line seven'
  end

  step 'I should see "line seven" in results' do
    expect(page).to have_content 'line seven'
  end

  step 'I should see "line four" in results' do
    expect(page).to have_content 'line four'
  end

  step 'I should see "line ten" in results' do
    expect(page).to have_content 'line ten'
  end

  step 'I should not see "line eleven" in results' do
    expect(page).not_to have_content 'line eleven'
  end

  step 'I should not see "line three" in results' do
    expect(page).not_to have_content 'line three'
  end

  step 'I should see "Personal snippet one" in results' do
    expect(page).to have_content 'Personal snippet one'
  end

  step 'I should see "Personal snippet private" in results' do
    expect(page).to have_content 'Personal snippet private'
  end

  step 'I should not see "Personal snippet one" in results' do
    expect(page).not_to have_content 'Personal snippet one'
  end

  step 'I should not see "Personal snippet private" in results' do
    expect(page).not_to have_content 'Personal snippet private'
  end

end
