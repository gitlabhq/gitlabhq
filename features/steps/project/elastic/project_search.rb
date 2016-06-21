class Spinach::Features::ProjectSearch < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject
  include SharedElastic
  include StubConfiguration

  before do
    [::Project, Repository, Note, MergeRequest, Milestone, ::ProjectWiki, Issue].each do |model|
      model.__elasticsearch__.create_index!
    end
  end

  after do
    [::Project, Repository, Note, MergeRequest, Milestone, ::ProjectWiki, Issue].each do |model|
      model.__elasticsearch__.delete_index!
    end

    stub_application_setting(elasticsearch_search: false, elasticsearch_indexing: false)
  end

  step 'project has all data available for the search' do
    @project = create :project
    @project.team << [current_user, :master]

    @issue = create :issue, title: 'bla-bla initial', project: @project
    @merge_request = create :merge_request, title: 'bla-bla initial', source_project: @project
    @milestone = create :milestone, title: 'bla-bla initial', project: @project
    @note = create :note, note: 'bla-bla initial', project: @project, noteable: @issue

    @project.repository.index_blobs
    @project.repository.index_commits

    @project.wiki.create_page("index_page", "Bla bla initial")
  end

  step 'I search "def"' do
    fill_in "search", with: "def"
    click_button "Go"
  end

  step 'I find a Comment' do
    select_filter("Comments")

    expect(page.find('.search-result-row')).to have_content(@note.note)
  end

  step 'I find a Wiki Page' do
    select_filter("Wiki")

    expect(page.find('.blob-result')).to have_content('Bla bla init')
  end

  step 'I find a Commit' do
    select_filter("Commits")

    expect(page.find('.search-result-row')).to have_content("Initial commit")
  end

  step 'I find a Code' do
    expect(page.first('.blob-result')).to have_content("def")
  end
end
