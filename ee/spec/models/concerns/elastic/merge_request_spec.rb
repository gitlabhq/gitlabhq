require 'spec_helper'

describe MergeRequest, :elastic do
  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  it "searches merge requests" do
    project = create :project, :repository

    Sidekiq::Testing.inline! do
      create :merge_request, title: 'bla-bla term1', source_project: project
      create :merge_request, description: 'term2 in description', source_project: project, target_branch: "feature2"
      create :merge_request, source_project: project, target_branch: "feature3"

      # The merge request you have no access to except as an administrator
      create :merge_request, title: 'also with term3', source_project: create(:project, :private)

      Gitlab::Elastic::Helper.refresh_index
    end

    options = { project_ids: [project.id] }

    expect(described_class.elastic_search('term1 | term2 | term3', options: options).total_count).to eq(2)
    expect(described_class.elastic_search(MergeRequest.last.to_reference, options: options).total_count).to eq(1)
    expect(described_class.elastic_search('term3', options: options).total_count).to eq(0)
    expect(described_class.elastic_search('term3', options: { project_ids: :any }).total_count).to eq(1)
  end

  it "returns json with all needed elements" do
    merge_request = create :merge_request

    expected_hash = merge_request.attributes.extract!(
      'id',
      'iid',
      'target_branch',
      'source_branch',
      'title',
      'description',
      'created_at',
      'updated_at',
      'state',
      'merge_status',
      'source_project_id',
      'target_project_id',
      'author_id'
    )

    expect(merge_request.as_indexed_json).to eq(expected_hash)
  end

  it_behaves_like 'no results when the user cannot read cross project' do
    let(:record1) { create(:merge_request, source_project: project, title: 'test-mr') }
    let(:record2) { create(:merge_request, source_project: project2, title: 'test-mr') }
  end
end
