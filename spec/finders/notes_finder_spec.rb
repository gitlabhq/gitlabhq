# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NotesFinder do
  let(:user) { create :user }
  let(:project) { create(:project) }

  before do
    project.add_maintainer(user)
  end

  describe '#execute' do
    context 'when notes filter is present' do
      let!(:comment) { create(:note_on_issue, project: project) }
      let!(:system_note) { create(:note_on_issue, project: project, system: true) }

      it 'returns only user notes when using only_comments filter' do
        finder = described_class.new(user, project: project, notes_filter: UserPreference::NOTES_FILTERS[:only_comments])

        notes = finder.execute

        expect(notes).to match_array(comment)
      end

      it 'returns only system notes when using only_activity filters' do
        finder = described_class.new(user, project: project, notes_filter: UserPreference::NOTES_FILTERS[:only_activity])

        notes = finder.execute

        expect(notes).to match_array(system_note)
      end

      it 'gets all notes' do
        finder = described_class.new(user, project: project, notes_filter: UserPreference::NOTES_FILTERS[:all_activity])

        notes = finder.execute

        expect(notes).to match_array([comment, system_note])
      end
    end

    it 'finds notes on merge requests' do
      create(:note_on_merge_request, project: project)

      notes = described_class.new(user, project: project).execute

      expect(notes.count).to eq(1)
    end

    it 'finds notes on snippets' do
      create(:note_on_project_snippet, project: project)

      notes = described_class.new(user, project: project).execute

      expect(notes.count).to eq(1)
    end

    it "excludes notes on commits the author can't download" do
      project = create(:project, :private, :repository)
      note = create(:note_on_commit, project: project)
      params = { target_type: 'commit', target_id: note.noteable.id }

      notes = described_class.new(create(:user), params).execute

      expect(notes.count).to eq(0)
    end

    it 'succeeds when no notes found' do
      notes = described_class.new(create(:user), project: project).execute

      expect(notes.count).to eq(0)
    end

    context 'on restricted projects' do
      let(:project) do
        create(:project,
               :public,
               :issues_private,
               :snippets_private,
               :merge_requests_private)
      end

      it 'publicly excludes notes on merge requests' do
        create(:note_on_merge_request, project: project)

        notes = described_class.new(create(:user), project: project).execute

        expect(notes.count).to eq(0)
      end

      it 'publicly excludes notes on issues' do
        create(:note_on_issue, project: project)

        notes = described_class.new(create(:user), project: project).execute

        expect(notes.count).to eq(0)
      end

      it 'publicly excludes notes on snippets' do
        create(:note_on_project_snippet, project: project)

        notes = described_class.new(create(:user), project: project).execute

        expect(notes.count).to eq(0)
      end
    end

    context 'for target type' do
      let(:project) { create(:project, :repository) }
      let!(:note1) { create :note_on_issue, project: project }
      let!(:note2) { create :note_on_commit, project: project }

      it 'finds only notes for the selected type' do
        notes = described_class.new(user, project: project, target_type: 'issue').execute

        expect(notes).to eq([note1])
      end
    end

    context 'for target' do
      let(:project) { create(:project, :repository) }
      let!(:note1) { create :note_on_commit, project: project }
      let!(:note2) { create :note_on_commit, project: project }
      let(:commit) { note1.noteable }
      let(:params) { { project: project, target_id: commit.id, target_type: 'commit', last_fetched_at: 1.hour.ago } }

      it 'finds all notes' do
        notes = described_class.new(user, params).execute
        expect(notes.size).to eq(2)
      end

      it 'finds notes on merge requests' do
        note = create(:note_on_merge_request, project: project)
        params = { project: project, target_type: 'merge_request', target_id: note.noteable.id }

        notes = described_class.new(user, params).execute

        expect(notes).to include(note)
      end

      it 'finds notes on snippets' do
        note = create(:note_on_project_snippet, project: project)
        params = { project: project, target_type: 'snippet', target_id: note.noteable.id }

        notes = described_class.new(user, params).execute

        expect(notes.count).to eq(1)
      end

      it 'finds notes on personal snippets' do
        note = create(:note_on_personal_snippet)
        params = { project: project, target_type: 'personal_snippet', target_id: note.noteable_id }

        notes = described_class.new(user, params).execute

        expect(notes.count).to eq(1)
      end

      it 'raises an exception for an invalid target_type' do
        params[:target_type] = 'invalid'
        expect { described_class.new(user, params).execute }.to raise_error("invalid target_type '#{params[:target_type]}'")
      end

      it 'filters out old notes' do
        note2.update_attribute(:updated_at, 2.hours.ago)
        notes = described_class.new(user, params).execute
        expect(notes).to eq([note1])
      end

      context 'confidential issue notes' do
        let(:confidential_issue) { create(:issue, :confidential, project: project, author: user) }
        let!(:confidential_note) { create(:note, noteable: confidential_issue, project: confidential_issue.project) }

        let(:params) { { project: confidential_issue.project, target_id: confidential_issue.id, target_type: 'issue', last_fetched_at: 1.hour.ago } }

        it 'returns notes if user can see the issue' do
          expect(described_class.new(user, params).execute).to eq([confidential_note])
        end

        it 'raises an error if user can not see the issue' do
          user = create(:user)
          expect { described_class.new(user, params).execute }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it 'raises an error for project members with guest role' do
          user = create(:user)
          project.add_guest(user)

          expect { described_class.new(user, params).execute }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context 'for explicit target' do
      let(:project) { create(:project, :repository) }
      let!(:note1) { create :note_on_commit, project: project, created_at: 1.day.ago, updated_at: 2.hours.ago }
      let!(:note2) { create :note_on_commit, project: project }
      let(:commit) { note1.noteable }
      let(:params) { { project: project, target: commit } }

      it 'returns the expected notes' do
        expect(described_class.new(user, params).execute).to eq([note1, note2])
      end

      it 'returns the expected notes when last_fetched_at is given' do
        params = { project: project, target: commit, last_fetched_at: 1.hour.ago }
        expect(described_class.new(user, params).execute).to eq([note2])
      end

      it 'fails when nil is provided' do
        params = { project: project, target: nil }
        expect { described_class.new(user, params).execute }.to raise_error(RuntimeError)
      end
    end

    describe 'sorting' do
      it 'allows sorting' do
        params = { project: project, sort: 'id_desc' }

        expect(Note).to receive(:order_id_desc).once

        described_class.new(user, params).execute
      end

      it 'defaults to sort by .fresh' do
        params = { project: project }

        expect(Note).to receive(:fresh).once

        described_class.new(user, params).execute
      end
    end
  end

  describe '.search' do
    let(:project) { create(:project, :public) }
    let(:note) { create(:note_on_issue, note: 'WoW', project: project) }

    it 'returns notes with matching content' do
      expect(described_class.new(nil, project: note.project, search: note.note).execute).to eq([note])
    end

    it 'returns notes with matching content regardless of the casing' do
      expect(described_class.new(nil, project: note.project, search: 'WOW').execute).to eq([note])
    end

    it 'returns commit notes user can access' do
      note = create(:note_on_commit, project: project)

      expect(described_class.new(create(:user), project: note.project, search: note.note).execute).to eq([note])
    end

    context "confidential issues" do
      let(:user) { create(:user) }
      let(:confidential_issue) { create(:issue, :confidential, project: project, author: user) }
      let(:confidential_note) { create(:note, note: "Random", noteable: confidential_issue, project: confidential_issue.project) }

      it "returns notes with matching content if user can see the issue" do
        expect(described_class.new(user, project: confidential_note.project, search: confidential_note.note).execute).to eq([confidential_note])
      end

      it "does not return notes with matching content if user can not see the issue" do
        user = create(:user)
        expect(described_class.new(user, project: confidential_note.project, search: confidential_note.note).execute).to be_empty
      end

      it "does not return notes with matching content for project members with guest role" do
        user = create(:user)
        project.add_guest(user)
        expect(described_class.new(user, project: confidential_note.project, search: confidential_note.note).execute).to be_empty
      end

      it "does not return notes with matching content for unauthenticated users" do
        expect(described_class.new(nil, project: confidential_note.project, search: confidential_note.note).execute).to be_empty
      end
    end

    context 'inlines SQL filters on subqueries for performance' do
      let(:sql) { described_class.new(nil, project: note.project, search: note.note).execute.to_sql }
      let(:number_of_noteable_types) { 4 }

      specify 'project_id check' do
        expect(sql.scan(/project_id/).count).to be >= (number_of_noteable_types + 2)
      end

      specify 'search filter' do
        expect(sql.scan(/LIKE/).count).to be >= number_of_noteable_types
      end
    end
  end

  describe '#target' do
    subject { described_class.new(user, params) }

    context 'for a issue target' do
      let(:issue) { create(:issue, project: project) }
      let(:params) { { project: project, target_type: 'issue', target_id: issue.id } }

      it 'returns the issue' do
        expect(subject.target).to eq(issue)
      end
    end

    context 'for a merge request target' do
      let(:merge_request) { create(:merge_request, source_project: project) }
      let(:params) { { project: project, target_type: 'merge_request', target_id: merge_request.id } }

      it 'returns the merge_request' do
        expect(subject.target).to eq(merge_request)
      end
    end

    context 'for a snippet target' do
      let(:snippet) { create(:project_snippet, project: project) }
      let(:params) { { project: project, target_type: 'snippet', target_id: snippet.id } }

      it 'returns the snippet' do
        expect(subject.target).to eq(snippet)
      end
    end

    context 'for a commit target' do
      let(:project) { create(:project, :repository) }
      let(:commit) { project.commit }
      let(:params) { { project: project, target_type: 'commit', target_id: commit.id } }

      it 'returns the commit' do
        expect(subject.target).to eq(commit)
      end
    end

    context 'target_iid' do
      let(:issue) { create(:issue, project: project) }
      let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

      it 'finds issues by iid' do
        iid_params = { project: project, target_type: 'issue', target_iid: issue.iid }
        expect(described_class.new(user, iid_params).target).to eq(issue)
      end

      it 'finds merge requests by iid' do
        iid_params = { project: project, target_type: 'merge_request', target_iid: merge_request.iid }
        expect(described_class.new(user, iid_params).target).to eq(merge_request)
      end

      it 'returns nil if both target_id and target_iid are not given' do
        params_without_any_id = { project: project, target_type: 'issue' }
        expect(described_class.new(user, params_without_any_id).target).to be_nil
      end

      it 'prioritizes target_id over target_iid' do
        issue2 = create(:issue, project: project)
        iid_params = { project: project, target_type: 'issue', target_id: issue2.id, target_iid: issue.iid }
        expect(described_class.new(user, iid_params).target).to eq(issue2)
      end
    end
  end
end
