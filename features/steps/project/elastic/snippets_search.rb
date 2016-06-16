class Spinach::Features::SnippetsSearch < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject
  include SharedElastic
  include StubConfiguration

  before do
    Snippet.__elasticsearch__.create_index!
  end

  after do
    Snippet.__elasticsearch__.delete_index!

    stub_application_setting(elasticsearch_search: false, elasticsearch_indexing: false)
  end

  step 'there is a snippet "index" with "php rocks" string' do
    create :personal_snippet, :public, content: "php rocks", title: "index"
    Snippet.__elasticsearch__.refresh_index!
  end

  step 'there is a snippet "php" with "benefits" string' do
    create :personal_snippet, :public, content: "benefits", title: "php"
    Snippet.__elasticsearch__.refresh_index!
  end

  step 'I search "php"' do
    fill_in "search", with: "php"
    click_button "Go"
  end

  step 'I find "index" snippet' do
    expect(page.find('.file-holder')).to have_content("php rocks")
  end

  step 'I select search by titles and filenames' do
    select_filter("Titles and Filenames")
  end

  step 'I find "php" snippet' do
    expect(page.find('.search-result-row')).to have_content("php")
  end
end
