require 'spec_helper'

describe EpicNoteEntity do
  include Gitlab::Routing

  let(:request) { double('request', current_user: user, noteable: note.noteable) }

  let(:entity) { described_class.new(note, request: request) }
  let(:epic) { create(:epic, author: user) }
  let(:note) { create(:note, noteable: epic, author: user) }
  let(:user) { create(:user) }
  subject { entity.as_json }

  it_behaves_like 'note entity'

  it 'exposes epic-specific elements' do
    expect(subject).to include(:toggle_award_path, :path)
  end
end
