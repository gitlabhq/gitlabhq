require 'spec_helper'

describe SystemNoteService do
  include ProjectForksHelper
  include Gitlab::Routing
  include RepoHelpers

  set(:group)    { create(:group) }
  let(:project)  { create(:project, :repository, group: group) }
  set(:author)   { create(:user) }
  let(:noteable) { create(:issue, project: project) }
  let(:issue)    { noteable }
  let(:epic)     { create(:epic) }

  shared_examples_for 'a system note' do
    let(:expected_noteable) { noteable }
    let(:commit_count)      { nil }

    it 'has the correct attributes', :aggregate_failures do
      expect(subject).to be_valid
      expect(subject).to be_system

      expect(subject.noteable).to eq expected_noteable
      expect(subject.project).to eq project
      expect(subject.author).to eq author

      expect(subject.system_note_metadata.action).to eq(action)
      expect(subject.system_note_metadata.commit_count).to eq(commit_count)
    end
  end
  describe '.change_weight_note' do
    context 'when weight changed' do
      let(:noteable) { create(:issue, project: project, title: 'Lorem ipsum', weight: 4) }

      subject { described_class.change_weight_note(noteable, project, author) }

      it_behaves_like 'a system note' do
        let(:action) { 'weight' }
      end

      it 'sets the note text' do
        expect(subject.note).to eq "changed weight to **4**,"
      end
    end

    context 'when weight removed' do
      let(:noteable) { create(:issue, project: project, title: 'Lorem ipsum', weight: nil) }

      subject { described_class.change_weight_note(noteable, project, author) }

      it_behaves_like 'a system note' do
        let(:action) { 'weight' }
      end

      it 'sets the note text' do
        expect(subject.note).to eq 'removed the weight'
      end
    end
  end
end
