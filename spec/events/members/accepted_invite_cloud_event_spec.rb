# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::AcceptedInviteCloudEvent, feature_category: :user_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }

  describe '.build' do
    let(:source) { project }
    let(:member_id) { 42 }
    let(:event) do
      described_class.build(source: source, current_user: user, user_id: user.id, member_id: member_id)
    end

    it_behaves_like 'a member base cloud event'

    it 'sets event_type to :accepted_invite' do
      expect(event.event_type).to eq(:accepted_invite)
    end

    it 'includes user_id and member_id in event data' do
      expect(event.event_data).to include(user_id: user.id, member_id: member_id)
    end

    context 'when source is a group' do
      let_it_be(:group) { create(:group) }
      let(:source) { group }

      it_behaves_like 'a member base cloud event'
    end
  end

  it_behaves_like 'a cloud event with schema',
    valid_data: {
      source_id: 1,
      source_type: 'Project',
      user_id: 2,
      member_id: 3
    },
    missing_required: %i[source_id source_type user_id member_id],
    invalid_types: {
      source_id: 'not_an_integer',
      source_type: 123,
      user_id: 'not_an_integer',
      member_id: 'not_an_integer'
    }
end
