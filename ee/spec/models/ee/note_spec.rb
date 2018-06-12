require 'spec_helper'

describe EE::Note do
  # Remove with https://gitlab.com/gitlab-org/gitlab-ee/issues/6347
  describe "#note and #note_html overrides for weight" do
    using RSpec::Parameterized::TableSyntax

    where(:system, :action, :result) do
      false | nil      | 'this, had, some, commas, originally'
      true  | nil      | 'this, had, some, commas, originally'
      true  | 'relate' | 'this, had, some, commas, originally'
      true  | 'weight' | 'this had some commas originally'
    end

    with_them do
      let(:note) { create(:note, system: system, note: 'this, had, some, commas, originally') }

      before do
        create(:system_note_metadata, action: action, note: note) if action
      end

      it 'returns the right raw note' do
        expect(note.note).to eq(result)
      end

      it 'returns the right HTML' do
        expect(note.note_html).to eq("<p dir=\"auto\">#{result}</p>")
      end
    end
  end
end
