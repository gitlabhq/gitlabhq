# frozen_string_literal: true

require "spec_helper"

describe Groups::GroupMembersHelper do
  describe '.group_member_select_options' do
    let(:group) { create(:group) }

    before do
      helper.instance_variable_set(:@group, group)
    end

    it 'returns an options hash' do
      expect(helper.group_member_select_options).to include(multiple: true, scope: :all, email_user: true)
    end
  end
end
