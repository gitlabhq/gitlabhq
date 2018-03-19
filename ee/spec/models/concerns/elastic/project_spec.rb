require 'spec_helper'

describe Project, :elastic do
  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  it "finds projects" do
    project_ids = []

    Sidekiq::Testing.inline! do
      project = create :project, name: 'test1'
      project1 = create :project, path: 'test2', description: 'awesome project'
      project2 = create :project
      create :project, path: 'someone_elses_project'
      project_ids += [project.id, project1.id, project2.id]

      # The project you have no access to except as an administrator
      create :project, :private, name: 'test3'

      Gitlab::Elastic::Helper.refresh_index
    end

    expect(described_class.elastic_search('test1', options: { project_ids: project_ids }).total_count).to eq(1)
    expect(described_class.elastic_search('test2', options: { project_ids: project_ids }).total_count).to eq(1)
    expect(described_class.elastic_search('awesome', options: { project_ids: project_ids }).total_count).to eq(1)
    expect(described_class.elastic_search('test*', options: { project_ids: project_ids }).total_count).to eq(2)
    expect(described_class.elastic_search('test*', options: { project_ids: :any }).total_count).to eq(3)
    expect(described_class.elastic_search('someone_elses_project', options: { project_ids: project_ids }).total_count).to eq(0)
  end

  it "finds partial matches in project names" do
    project_ids = []

    Sidekiq::Testing.inline! do
      project = create :project, name: 'tesla-model-s'
      project1 = create :project, name: 'tesla_model_s'
      project_ids += [project.id, project1.id]

      Gitlab::Elastic::Helper.refresh_index
    end

    expect(described_class.elastic_search('tesla', options: { project_ids: project_ids }).total_count).to eq(2)
  end

  it "returns json with all needed elements" do
    project = create :project

    expected_hash = project.attributes.extract!(
      'id',
      'name',
      'path',
      'description',
      'namespace_id',
      'created_at',
      'archived',
      'updated_at',
      'visibility_level',
      'last_activity_at'
    )

    expected_hash.merge!(
      project.project_feature.attributes.extract!(
        'issues_access_level',
        'merge_requests_access_level',
        'snippets_access_level',
        'wiki_access_level',
        'repository_access_level'
      )
    )

    expected_hash['name_with_namespace'] = project.full_name
    expected_hash['path_with_namespace'] = project.full_path

    expect(project.as_indexed_json).to eq(expected_hash)
  end
end
