require 'spec_helper'

describe GroupsFinder do
  let(:user) { create :user }
  let!(:group) { create :group }
  let!(:public_group) { create :group, public: true }
  
  describe :execute do
    it 'finds public group' do
      groups = GroupsFinder.new.execute(user)
      expect(groups.size).to eq(1)
      expect(groups.first).to eq(public_group)
    end
  end
end
