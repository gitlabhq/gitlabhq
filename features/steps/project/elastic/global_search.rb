require Rails.root.join('spec', 'support', 'stub_configuration')

class Spinach::Features::GlobalSearch < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject
  include SharedElastic
  include StubConfiguration

  before do
    [::Project, Issue, MergeRequest, Milestone].each do |model|
      model.__elasticsearch__.create_index!
    end
  end

  after do
    [::Project, Issue, MergeRequest, Milestone].each do |model|
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
  end
end
