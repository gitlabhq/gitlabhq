# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::UpdatedCloudEvent, feature_category: :user_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }

  describe '.build' do
    let(:source) { project }
    let_it_be(:user_ids) { [1, 2, 3] }
    let(:event) { described_class.build(source: source, current_user: user, user_ids: user_ids) }

    it_behaves_like 'a member base cloud event'

    it 'sets event_type to :updated' do
      expect(event.event_type).to eq(:updated)
    end

    it 'includes user_ids in event data' do
      expect(event.event_data[:user_ids]).to eq(user_ids)
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
      user_ids: [2, 3]
    },
    missing_required: %i[source_id source_type user_ids],
    invalid_types: {
      source_id: 'not_an_integer',
      source_type: 123,
      user_ids: 'not_an_array'
    }
end
