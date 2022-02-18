# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Crm::ContactsFinder do
  let_it_be(:user) { create(:user) }

  describe '#execute' do
    subject { described_class.new(user, group: group).execute }

    context 'when customer relations feature is enabled for the group' do
      let_it_be(:root_group) { create(:group, :crm_enabled) }
      let_it_be(:group) { create(:group, parent: root_group) }

      let_it_be(:contact_1) { create(:contact, group: root_group) }
      let_it_be(:contact_2) { create(:contact, group: root_group) }

      context 'when user does not have permissions to see contacts in the group' do
        it 'returns an empty array' do
          expect(subject).to be_empty
        end
      end

      context 'when user is member of the root group' do
        before do
          root_group.add_developer(user)
        end

        context 'when feature flag is disabled' do
          before do
            stub_feature_flags(customer_relations: false)
          end

          it 'returns an empty array' do
            expect(subject).to be_empty
          end
        end

        context 'when feature flag is enabled' do
          it 'returns all group contacts' do
            expect(subject).to match_array([contact_1, contact_2])
          end
        end
      end

      context 'when user is member of the sub group' do
        before do
          group.add_developer(user)
        end

        it 'returns an empty array' do
          expect(subject).to be_empty
        end
      end
    end

    context 'when customer relations feature is disabled for the group' do
      let_it_be(:group) { create(:group) }
      let_it_be(:contact) { create(:contact, group: group) }

      before do
        group.add_developer(user)
      end

      it 'returns an empty array' do
        expect(subject).to be_empty
      end
    end
  end
end
