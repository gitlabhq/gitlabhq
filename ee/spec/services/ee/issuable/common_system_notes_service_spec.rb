require 'spec_helper'

describe Issuable::CommonSystemNotesService do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:issuable) { create(:issue) }

  describe '#execute' do
    it_behaves_like 'system note creation', { weight: 5 }, 'changed weight to **5**,'
  end
end
