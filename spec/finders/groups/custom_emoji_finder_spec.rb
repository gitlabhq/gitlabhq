# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::CustomEmojiFinder, feature_category: :code_review_workflow do
  describe '#execute' do
    let(:params) { {} }

    subject(:execute) { described_class.new(group, params).execute }

    context 'when inside a group' do
      let_it_be(:group) { create(:group) }
      let_it_be(:custom_emoji) { create(:custom_emoji, group: group) }

      it 'returns custom emoji from group' do
        expect(execute).to contain_exactly(custom_emoji)
      end
    end

    context 'when group is nil' do
      let_it_be(:group) { nil }

      it 'returns nil' do
        expect(execute).to be_empty
      end
    end

    context 'when group is a subgroup' do
      let_it_be(:parent) { create(:group) }
      let_it_be(:group) { create(:group, parent: parent) }
      let_it_be(:custom_emoji) { create(:custom_emoji, group: group) }

      it 'returns custom emoji' do
        expect(described_class.new(group, params).execute).to contain_exactly(custom_emoji)
      end
    end

    describe 'when custom emoji is in parent group' do
      let_it_be(:parent) { create(:group) }
      let_it_be(:group) { create(:group, parent: parent) }
      let_it_be(:custom_emoji) { create(:custom_emoji, group: parent) }
      let(:params) { { include_ancestor_groups: true } }

      it 'returns custom emoji' do
        expect(execute).to contain_exactly(custom_emoji)
      end

      context 'when params is empty' do
        let(:params) { {} }

        it 'returns empty record' do
          expect(execute).to eq([])
        end
      end

      context 'when include_ancestor_groups is false' do
        let(:params) { { include_ancestor_groups: false } }

        it 'returns empty record' do
          expect(execute).to eq([])
        end
      end
    end
  end
end
