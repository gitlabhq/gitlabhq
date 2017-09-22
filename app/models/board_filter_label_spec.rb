require 'spec_helper'

describe BoardFilterLabel, type: :model do
  describe 'validations' do
    subject { create(:board_filter_label) }

    it { is_expected.to validate_presence_of(:board_filter) }
    it { is_expected.to validate_presence_of(:label) }
    it { is_expected.to validate_uniqueness_of(:board_filter).scoped_to(:label_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:board_filter) }
    it { is_expected.to belong_to(:label) }
  end
end