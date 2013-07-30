class Spinach::Features::PublicSnippetsFeature < Spinach::FeatureSteps
  include SharedPaths

  step 'world public snippet "World Public Snippet"' do
    create :snippet, title: "World Public Snippet", visibility: :world_public
  end

  step 'gitlab public snippet "Gitlab Public Snippet"' do
    create :snippet, title: "Gitlab Public Snippet", visibility: :gitlab_public
  end

  step 'private snippet "Private Snippet"' do
    create :snippet, title: "Private Snippet", visibility: :private
  end

  step 'I should see snippet "World Public Snippet"' do
    page.should have_content "World Public Snippet"
  end

  step 'I should not see snippet "World Public Snippet"' do
    page.should_not have_content "World Public Snippet"
  end

  step 'I should not see snippet "Gitlab Public Snippet"' do
    page.should_not have_content "Gitlab Public Snippet"
  end

  step 'I should not see snippet "Private Snippet"' do
    page.should_not have_content "Private Snippet"
  end
end

