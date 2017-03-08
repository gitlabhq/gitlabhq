class Spinach::Features::SnippetsSearch < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject
  include SharedElastic
  include StubConfiguration

  before do
    Gitlab::Elastic::Helper.create_empty_index
  end

  after do
    Gitlab::Elastic::Helper.delete_index

    stub_application_setting(elasticsearch_search: false, elasticsearch_indexing: false)
  end

  step 'there is a snippet "index" with "php rocks" string' do
    create :personal_snippet, :public, content: "php rocks", title: "index"
    Gitlab::Elastic::Helper.refresh_index
  end

  step 'there is a snippet "php" with "benefits" string' do
    create :personal_snippet, :public, content: "benefits", title: "php"
    Gitlab::Elastic::Helper.refresh_index
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
