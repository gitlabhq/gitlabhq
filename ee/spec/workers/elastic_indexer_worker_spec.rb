require 'spec_helper'

describe ElasticIndexerWorker, :elastic do
  subject { described_class.new }

  before do
    stub_ee_application_setting(elasticsearch_indexing: true)

    Elasticsearch::Model.client =
      Gitlab::Elastic::Client.build(Gitlab::CurrentSettings.elasticsearch_config)
  end

  it 'returns true if ES disabled' do
    stub_ee_application_setting(elasticsearch_indexing: false)

    expect_any_instance_of(Elasticsearch::Model).not_to receive(:__elasticsearch__)

    expect(subject.perform("index", "Milestone", 1)).to be_truthy
  end

  describe 'Indexing new records' do
    it 'indexes a project' do
      project = nil

      Sidekiq::Testing.disable! do
        project = create :project
      end

      expect do
        subject.perform("index", "Project", project.id)
        Gitlab::Elastic::Helper.refresh_index
      end.to change { Elasticsearch::Model.search('*').records.size }.by(1)
    end

    it 'indexes an issue' do
      issue = nil

      Sidekiq::Testing.disable! do
        issue = create :issue
      end

      expect do
        subject.perform("index", "Issue", issue.id)
        Gitlab::Elastic::Helper.refresh_index
      end.to change { Elasticsearch::Model.search('*').records.size }.by(1)
    end

    it 'indexes a note' do
      note = nil

      Sidekiq::Testing.disable! do
        note = create :note
      end

      expect do
        subject.perform("index", "Note", note.id)
        Gitlab::Elastic::Helper.refresh_index
      end.to change { Elasticsearch::Model.search('*').records.size }.by(1)
    end

    it 'indexes a milestone' do
      milestone = nil

      Sidekiq::Testing.disable! do
        milestone = create :milestone
      end

      expect do
        subject.perform("index", "Milestone", milestone.id)
        Gitlab::Elastic::Helper.refresh_index
      end.to change { Elasticsearch::Model.search('*').records.size }.by(1)
    end

    it 'indexes a merge request' do
      merge_request = nil

      Sidekiq::Testing.disable! do
        merge_request = create :merge_request
      end

      expect do
        subject.perform("index", "MergeRequest", merge_request.id)
        Gitlab::Elastic::Helper.refresh_index
      end.to change { Elasticsearch::Model.search('*').records.size }.by(1)
    end
  end

  describe 'Updating index' do
    it 'updates a project' do
      project = nil

      Sidekiq::Testing.disable! do
        project = create :project
        subject.perform("index", "Project", project.id)
        project.update(name: "new")
      end

      expect do
        subject.perform("update", "Project", project.id)
        Gitlab::Elastic::Helper.refresh_index
      end.to change { Elasticsearch::Model.search('new').records.size }.by(1)
    end

    it 'updates an issue' do
      issue = nil

      Sidekiq::Testing.disable! do
        issue = create :issue
        subject.perform("index", "Issue", issue.id)
        issue.update(title: "new")
      end

      expect do
        subject.perform("update", "Issue", issue.id)
        Gitlab::Elastic::Helper.refresh_index
      end.to change { Elasticsearch::Model.search('new').records.size }.by(1)
    end

    it 'updates a note' do
      note = nil

      Sidekiq::Testing.disable! do
        note = create :note
        subject.perform("index", "Note", note.id)
        note.update(note: 'new')
      end

      expect do
        subject.perform("update", "Note", note.id)
        Gitlab::Elastic::Helper.refresh_index
      end.to change { Elasticsearch::Model.search('new').records.size }.by(1)
    end

    it 'updates a milestone' do
      milestone = nil

      Sidekiq::Testing.disable! do
        milestone = create :milestone
        subject.perform("index", "Milestone", milestone.id)
        milestone.update(title: 'new')
      end

      expect do
        subject.perform("update", "Milestone", milestone.id)
        Gitlab::Elastic::Helper.refresh_index
      end.to change { Elasticsearch::Model.search('new').records.size }.by(1)
    end

    it 'updates a merge request' do
      merge_request = nil

      Sidekiq::Testing.disable! do
        merge_request = create :merge_request
        subject.perform("index", "MergeRequest", merge_request.id)
        merge_request.update(title: 'new')
      end

      expect do
        subject.perform("index", "MergeRequest", merge_request.id)
        Gitlab::Elastic::Helper.refresh_index
      end.to change { Elasticsearch::Model.search('new').records.size }.by(1)
    end
  end

  describe 'Delete' do
    it 'deletes a project with all nested objects' do
      project, issue, milestone, note, merge_request = nil

      Sidekiq::Testing.disable! do
        project = create :project, :repository
        subject.perform("index", "Project", project.id)

        issue = create :issue, project: project
        subject.perform("index", "Issue", issue.id)

        milestone = create :milestone, project: project
        subject.perform("index", "Milestone", milestone.id)

        note = create :note, project: project
        subject.perform("index", "Note", note.id)

        merge_request = create :merge_request, target_project: project, source_project: project
        subject.perform("index", "MergeRequest", merge_request.id)
      end

      ElasticCommitIndexerWorker.new.perform(project.id)
      Gitlab::Elastic::Helper.refresh_index

      ## All database objects + data from repository. The absolute value does not matter
      expect(Elasticsearch::Model.search('*').total_count).to be > 40

      subject.perform("delete", "Project", project.id)
      Gitlab::Elastic::Helper.refresh_index

      expect(Elasticsearch::Model.search('*').total_count).to be(0)
    end

    it 'deletes an issue' do
      issue, project_id = nil

      Sidekiq::Testing.disable! do
        issue = create :issue
        subject.perform("index", "Issue", issue.id)
        Gitlab::Elastic::Helper.refresh_index
        project_id = issue.project_id
        issue.destroy
      end

      expect do
        subject.perform("delete", "Issue", issue.id, "project_id" => project_id)
        Gitlab::Elastic::Helper.refresh_index
      end.to change { Elasticsearch::Model.search('*').total_count }.by(-1)
    end

    it 'deletes a note' do
      note, project_id = nil

      Sidekiq::Testing.disable! do
        note = create :note
        subject.perform("index", "Note", note.id)
        Gitlab::Elastic::Helper.refresh_index
        project_id = note.project_id
        note.destroy
      end

      expect do
        subject.perform("delete", "Note", note.id, "project_id" => project_id)
        Gitlab::Elastic::Helper.refresh_index
      end.to change { Elasticsearch::Model.search('*').total_count }.by(-1)
    end

    it 'deletes a milestone' do
      milestone, project_id = nil

      Sidekiq::Testing.disable! do
        milestone = create :milestone
        subject.perform("index", "Milestone", milestone.id)
        Gitlab::Elastic::Helper.refresh_index
        project_id = milestone.project_id
        milestone.destroy
      end

      expect do
        subject.perform("delete", "Milestone", milestone.id, "project_id" => project_id)
        Gitlab::Elastic::Helper.refresh_index
      end.to change { Elasticsearch::Model.search('*').total_count }.by(-1)
    end

    it 'deletes a merge request' do
      merge_request, project_id = nil

      Sidekiq::Testing.disable! do
        merge_request = create :merge_request
        subject.perform("index", "MergeRequest", merge_request.id)
        Gitlab::Elastic::Helper.refresh_index
        project_id = merge_request.target_project_id
        merge_request.destroy
      end

      expect do
        subject.perform("delete", "MergeRequest", merge_request.id, "project_id" => project_id)
        Gitlab::Elastic::Helper.refresh_index
      end.to change { Elasticsearch::Model.search('*').total_count }.by(-1)
    end
  end
end
