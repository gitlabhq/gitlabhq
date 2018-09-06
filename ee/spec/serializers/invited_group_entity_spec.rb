# frozen_string_literal: true

require 'spec_helper'

describe InvitedGroupEntity do
  describe '#as_json' do
    let(:group) { build(:group, id: 1) }

    subject { described_class.new(group).as_json }

    it 'includes the group ID' do
      expect(subject[:id]).to eq(group.id)
    end

    it 'includes the group name' do
      expect(subject[:name]).to eq(group.name)
    end

    it 'includes the group avatar URL' do
      expect(subject[:avatar_url]).to eq(group.avatar_url)
    end
  end
end
