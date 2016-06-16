module SharedElastic
  include Spinach::DSL

  step 'I search "initial"' do
    fill_in "search", with: "initial"
    click_button "Go"
  end

  step 'I find an Issue' do
    select_filter("Issues")

    expect(page.find('.search-result-row')).to have_content(@issue.title)
  end

  step 'I find a Merge Request' do
    select_filter("Merge requests")

    expect(page.find('.search-result-row')).to have_content(@merge_request.title)
  end

  step 'I find a Milestone' do
    select_filter("Milestones")

    expect(page.find('.search-result-row')).to have_content(@milestone.title)
  end

  step 'Elasticsearch is enabled' do
    stub_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  def select_filter(name)
    find(:xpath, "//ul[contains(@class, 'search-filter')]//a[contains(.,'#{name}')]").click
  end
end
