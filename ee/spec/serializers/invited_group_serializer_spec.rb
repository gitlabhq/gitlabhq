# frozen_string_literal: true

require 'spec_helper'

describe InvitedGroupSerializer do
  describe '#represent' do
    it 'includes the id, name, and avatar URL' do
      group = build(:group, id: 1)
      output = described_class.new.represent(group)

      expect(output).to include(:id, :name, :avatar_url)
    end
  end
end
