# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::AddedCloudEvent, feature_category: :user_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }

  describe '.build' do
    let(:invited_user_ids) { [1, 2, 3] }
    let(:event) do
      described_class.build(source: source, current_user: user, invited_user_ids: invited_user_ids)
    end

    shared_examples 'a members added cloud event' do
      it_behaves_like 'a member base cloud event'

      it 'sets event_type to :added' do
        expect(event.event_type).to eq(:added)
      end

      it 'includes invited_user_ids in event data' do
        expect(event.event_data[:invited_user_ids]).to eq(invited_user_ids)
      end
    end

    context 'when source is a project' do
      let(:source) { project }

      it_behaves_like 'a members added cloud event'
    end

    context 'when source is a group' do
      let_it_be(:group) { create(:group) }
      let(:source) { group }

      it_behaves_like 'a members added cloud event'
    end
  end

  it_behaves_like 'a cloud event with schema',
    valid_data: {
      source_id: 1,
      source_type: 'Project',
      invited_user_ids: [2, 3]
    },
    missing_required: %i[source_id source_type invited_user_ids],
    invalid_types: {
      source_id: 'not_an_integer',
      source_type: 123,
      invited_user_ids: 'not_an_array'
    }
end
