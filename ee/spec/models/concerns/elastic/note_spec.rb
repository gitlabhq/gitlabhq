require 'spec_helper'

describe Note, :elastic do
  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  it "searches notes" do
    issue = create :issue

    Sidekiq::Testing.inline! do
      create :note, note: 'bla-bla term1', project: issue.project
      create :note, project: issue.project

      # The note in the project you have no access to except as an administrator
      create :note, note: 'bla-bla term2'

      Gitlab::Elastic::Helper.refresh_index
    end

    options = { project_ids: [issue.project.id] }

    expect(described_class.elastic_search('term1 | term2', options: options).total_count).to eq(1)
    expect(described_class.elastic_search('bla-bla', options: options).total_count).to eq(1)
    expect(described_class.elastic_search('bla-bla', options: { project_ids: :any }).total_count).to eq(2)
  end

  it "indexes && searches diff notes" do
    notes = []

    Sidekiq::Testing.inline! do
      notes << create(:diff_note_on_merge_request, note: "term")
      notes << create(:diff_note_on_commit, note: "term")
      notes << create(:legacy_diff_note_on_merge_request, note: "term")
      notes << create(:legacy_diff_note_on_commit, note: "term")

      Gitlab::Elastic::Helper.refresh_index
    end

    project_ids = notes.map { |note| note.noteable.project.id }
    options = { project_ids: project_ids }

    expect(described_class.elastic_search('term', options: options).total_count).to eq(4)
  end

  it "returns json with all needed elements" do
    note = create :note

    expected_hash_keys = %w(
      id
      note
      project_id
      noteable_type
      noteable_id
      created_at
      updated_at
      issue
    )

    expect(note.as_indexed_json.keys).to eq(expected_hash_keys)
  end

  it "does not create ElasticIndexerWorker job for system messages" do
    project = create :project, :repository
    # We have to set one minute delay because of https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/15682
    issue = create :issue, project: project, updated_at: 1.minute.ago

    # Only issue should be updated
    expect(ElasticIndexerWorker).to receive(:perform_async).with(:update, 'Issue', anything, anything)
    create :note, :system, project: project, noteable: issue
  end

  context 'notes to confidential issues' do
    it "does not find note" do
      issue = create :issue, :confidential

      Sidekiq::Testing.inline! do
        create_notes_for(issue, 'bla-bla term')
        Gitlab::Elastic::Helper.refresh_index
      end

      options = { project_ids: [issue.project.id] }

      expect(Note.elastic_search('term', options: options).total_count).to eq(0)
    end

    it "finds note when user is authorized to see it" do
      user = create :user
      issue = create :issue, :confidential, author: user

      Sidekiq::Testing.inline! do
        create_notes_for(issue, 'bla-bla term')
        Gitlab::Elastic::Helper.refresh_index
      end

      options = { project_ids: [issue.project.id], current_user: user }

      expect(Note.elastic_search('term', options: options).total_count).to eq(1)
    end

    [:admin, :auditor].each do |user_type|
      it "finds note for #{user_type}" do
        superuser = create(user_type)
        issue = create(:issue, :confidential, author: create(:user))

        Sidekiq::Testing.inline! do
          create_notes_for(issue, 'bla-bla term')
          Gitlab::Elastic::Helper.refresh_index
        end

        options = { project_ids: [issue.project.id], current_user: superuser }

        expect(Note.elastic_search('term', options: options).total_count).to eq(1)
      end
    end

    it "return notes with matching content for project members" do
      user = create :user
      issue = create :issue, :confidential, author: user

      member = create(:user)
      issue.project.add_developer(member)

      Sidekiq::Testing.inline! do
        create_notes_for(issue, 'bla-bla term')
        Gitlab::Elastic::Helper.refresh_index
      end

      options = { project_ids: [issue.project.id], current_user: member }

      expect(Note.elastic_search('term', options: options).total_count).to eq(1)
    end

    it "does not return notes with matching content for project members with guest role" do
      user = create :user
      issue = create :issue, :confidential, author: user

      member = create(:user)
      issue.project.add_guest(member)

      Sidekiq::Testing.inline! do
        create_notes_for(issue, 'bla-bla term')
        Gitlab::Elastic::Helper.refresh_index
      end

      options = { project_ids: [issue.project.id], current_user: member }

      expect(Note.elastic_search('term', options: options).total_count).to eq(0)
    end
  end

  it_behaves_like 'no results when the user cannot read cross project' do
    let(:issue1) { create(:issue, project: project) }
    let(:issue2) { create(:issue, project: project2) }
    let(:record1) { create :note, note: 'test-note', project: issue1.project, noteable: issue1 }
    let(:record2) { create :note, note: 'test-note', project: issue2.project, noteable: issue2 }
  end

  def create_notes_for(issue, note)
    create :note, note: note, project: issue.project, noteable: issue
    create :note, project: issue.project, noteable: issue
  end
end
