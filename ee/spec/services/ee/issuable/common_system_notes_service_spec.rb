require 'spec_helper'

describe Issuable::CommonSystemNotesService do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:issuable) { create(:issue) }

  describe '#execute' do
    it_behaves_like 'system note creation', { weight: 5 }, 'changed weight to **5**,'

    context 'when issuable is an epic' do
      let(:timestamp) { Time.now }
      let(:issuable) { create(:epic, end_date: timestamp) }

      subject { described_class.new(nil, user).execute(issuable, [])}

      before do
        issuable.assign_attributes(start_date: timestamp, end_date: nil)
        issuable.save
      end

      it 'creates 2 system notes with the correct content' do
        expect { subject }.to change { Note.count }.from(0).to(2)

        expect(Note.first.note).to match("changed start date to #{timestamp.strftime('%b %-d, %Y')}")
        expect(Note.second.note).to match('removed the finish date')
      end
    end
  end
end
