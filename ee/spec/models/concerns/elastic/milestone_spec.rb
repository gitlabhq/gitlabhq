require 'spec_helper'

describe Milestone, :elastic do
  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  it "searches milestones" do
    project = create :project

    Sidekiq::Testing.inline! do
      create :milestone, title: 'bla-bla term1', project: project
      create :milestone, description: 'bla-bla term2', project: project
      create :milestone, project: project

      # The milestone you have no access to except as an administrator
      create :milestone, title: 'bla-bla term3'

      Gitlab::Elastic::Helper.refresh_index
    end

    options = { project_ids: [project.id] }

    expect(described_class.elastic_search('(term1 | term2 | term3) +bla-bla', options: options).total_count).to eq(2)
    expect(described_class.elastic_search('bla-bla', options: { project_ids: :any }).total_count).to eq(3)
  end

  it "returns json with all needed elements" do
    milestone = create :milestone

    expected_hash = milestone.attributes.extract!(
      'id',
      'title',
      'description',
      'project_id',
      'created_at',
      'updated_at'
    )

    expect(milestone.as_indexed_json).to eq(expected_hash)
  end

  it_behaves_like 'no results when the user cannot read cross project' do
    let(:record1) { create(:milestone, project: project, title: 'test-milestone') }
    let(:record2) { create(:milestone, project: project2, title: 'test-milestone') }
  end
end
