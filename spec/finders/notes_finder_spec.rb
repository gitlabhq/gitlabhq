require 'spec_helper'

describe NotesFinder do
  let(:user) { create :user }
  let(:project) { create(:project) }

  before do
    project.add_master(user)
  end

  describe '#execute' do
    it 'finds notes on merge requests' do
      create(:note_on_merge_request, project: project)

      notes = described_class.new(project, user).execute

      expect(notes.count).to eq(1)
    end

    it 'finds notes on snippets' do
      create(:note_on_project_snippet, project: project)

      notes = described_class.new(project, user).execute

      expect(notes.count).to eq(1)
    end

    it "excludes notes on commits the author can't download" do
      project = create(:project, :private, :repository)
      note = create(:note_on_commit, project: project)
      params = { target_type: 'commit', target_id: note.noteable.id }

      notes = described_class.new(project, create(:user), params).execute

      expect(notes.count).to eq(0)
    end

    it 'succeeds when no notes found' do
      notes = described_class.new(project, create(:user)).execute

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

        notes = described_class.new(project, create(:user)).execute

        expect(notes.count).to eq(0)
      end

      it 'publicly excludes notes on issues' do
        create(:note_on_issue, project: project)

        notes = described_class.new(project, create(:user)).execute

        expect(notes.count).to eq(0)
      end

      it 'publicly excludes notes on snippets' do
        create(:note_on_project_snippet, project: project)

        notes = described_class.new(project, create(:user)).execute

        expect(notes.count).to eq(0)
      end
    end

    context 'for target type' do
      let(:project) { create(:project, :repository) }
      let!(:note1) { create :note_on_issue, project: project }
      let!(:note2) { create :note_on_commit, project: project }

      it 'finds only notes for the selected type' do
        notes = described_class.new(project, user, target_type: 'issue').execute

        expect(notes).to eq([note1])
      end
    end

    context 'for target' do
      let(:project) { create(:project, :repository) }
      let(:note1) { create :note_on_commit, project: project }
      let(:note2) { create :note_on_commit, project: project }
      let(:commit) { note1.noteable }
      let(:params)  { { target_id: commit.id, target_type: 'commit', last_fetched_at: 1.hour.ago.to_i } }

      before do
        note1
        note2
      end

      it 'finds all notes' do
        notes = described_class.new(project, user, params).execute
        expect(notes.size).to eq(2)
      end

      it 'finds notes on merge requests' do
        note = create(:note_on_merge_request, project: project)
        params = { target_type: 'merge_request', target_id: note.noteable.id }

        notes = described_class.new(project, user, params).execute

        expect(notes).to include(note)
      end

      it 'finds notes on snippets' do
        note = create(:note_on_project_snippet, project: project)
        params = { target_type: 'snippet', target_id: note.noteable.id }

        notes = described_class.new(project, user, params).execute

        expect(notes.count).to eq(1)
      end

      it 'finds notes on personal snippets' do
        note = create(:note_on_personal_snippet)
        params = { target_type: 'personal_snippet', target_id: note.noteable_id }

        notes = described_class.new(project, user, params).execute

        expect(notes.count).to eq(1)
      end

      it 'raises an exception for an invalid target_type' do
        params[:target_type] = 'invalid'
        expect { described_class.new(project, user, params).execute }.to raise_error('invalid target_type')
      end

      it 'filters out old notes' do
        note2.update_attribute(:updated_at, 2.hours.ago)
        notes = described_class.new(project, user, params).execute
        expect(notes).to eq([note1])
      end

      context 'confidential issue notes' do
        let(:confidential_issue) { create(:issue, :confidential, project: project, author: user) }
        let!(:confidential_note) { create(:note, noteable: confidential_issue, project: confidential_issue.project) }

        let(:params) { { target_id: confidential_issue.id, target_type: 'issue', last_fetched_at: 1.hour.ago.to_i } }

        it 'returns notes if user can see the issue' do
          expect(described_class.new(project, user, params).execute).to eq([confidential_note])
        end

        it 'raises an error if user can not see the issue' do
          user = create(:user)
          expect { described_class.new(project, user, params).execute }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it 'raises an error for project members with guest role' do
          user = create(:user)
          project.add_guest(user)

          expect { described_class.new(project, user, params).execute }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  describe '.search' do
    let(:project) { create(:project, :public) }
    let(:note) { create(:note_on_issue, note: 'WoW', project: project) }

    it 'returns notes with matching content' do
      expect(described_class.new(note.project, nil, search: note.note).execute).to eq([note])
    end

    it 'returns notes with matching content regardless of the casing' do
      expect(described_class.new(note.project, nil, search: 'WOW').execute).to eq([note])
    end

    it 'returns commit notes user can access' do
      note = create(:note_on_commit, project: project)

      expect(described_class.new(note.project, create(:user), search: note.note).execute).to eq([note])
    end

    context "confidential issues" do
      let(:user) { create(:user) }
      let(:confidential_issue) { create(:issue, :confidential, project: project, author: user) }
      let(:confidential_note) { create(:note, note: "Random", noteable: confidential_issue, project: confidential_issue.project) }

      it "returns notes with matching content if user can see the issue" do
        expect(described_class.new(confidential_note.project, user, search: confidential_note.note).execute).to eq([confidential_note])
      end

      it "does not return notes with matching content if user can not see the issue" do
        user = create(:user)
        expect(described_class.new(confidential_note.project, user, search: confidential_note.note).execute).to be_empty
      end

      it "does not return notes with matching content for project members with guest role" do
        user = create(:user)
        project.add_guest(user)
        expect(described_class.new(confidential_note.project, user, search: confidential_note.note).execute).to be_empty
      end

      it "does not return notes with matching content for unauthenticated users" do
        expect(described_class.new(confidential_note.project, nil, search: confidential_note.note).execute).to be_empty
      end
    end

    context 'inlines SQL filters on subqueries for performance' do
      let(:sql) { described_class.new(note.project, nil, search: note.note).execute.to_sql }
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
    subject { described_class.new(project, user, params) }

    context 'for a issue target' do
      let(:issue) { create(:issue, project: project) }
      let(:params) { { target_type: 'issue', target_id: issue.id } }

      it 'returns the issue' do
        expect(subject.target).to eq(issue)
      end
    end

    context 'for a merge request target' do
      let(:merge_request) { create(:merge_request, source_project: project) }
      let(:params) { { target_type: 'merge_request', target_id: merge_request.id } }

      it 'returns the merge_request' do
        expect(subject.target).to eq(merge_request)
      end
    end

    context 'for a snippet target' do
      let(:snippet) { create(:project_snippet, project: project) }
      let(:params) { { target_type: 'snippet', target_id: snippet.id } }

      it 'returns the snippet' do
        expect(subject.target).to eq(snippet)
      end
    end

    context 'for a commit target' do
      let(:project) { create(:project, :repository) }
      let(:commit) { project.commit }
      let(:params) { { target_type: 'commit', target_id: commit.id } }

      it 'returns the commit' do
        expect(subject.target).to eq(commit)
      end
    end
  end
end
