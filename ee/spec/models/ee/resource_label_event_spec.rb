# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResourceLabelEvent, type: :model do
  subject { build(:resource_label_event) }
  let(:epic) { create(:epic) }

  describe 'validations' do
    describe 'Issuable validation' do
      it 'is valid if only epic_id is set' do
        subject.attributes = { epic: epic, issue: nil, merge_request: nil }

        expect(subject).to be_valid
      end
    end
  end
end
