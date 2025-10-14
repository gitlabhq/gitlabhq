# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Users::GroupCallouts::Create, feature_category: :shared do
  include GraphqlHelpers

  let_it_be(:group) { create(:group, :private) }
  let_it_be(:current_user) { create(:user) }

  let(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  describe '#resolve' do
    subject(:resolve) { mutation.resolve(feature_name: feature_name, group_id: group.to_global_id) }

    context 'when user does not have permission to read the group' do
      let(:feature_name) { Users::GroupCallout.feature_names.each_key.first.to_s }

      it 'raises an error' do
        expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when user has permission to read the group' do
      before_all do
        group.add_guest(current_user)
      end

      context 'when feature name is not supported' do
        let(:feature_name) { 'not_supported' }

        it 'does not create a user group callout' do
          expect { resolve }.not_to change { Users::GroupCallout.count }.from(0)
        end

        it 'returns error about feature name not being supported' do
          expect(resolve[:errors]).to include("Feature name is not included in the list")
        end
      end

      context 'when feature name is supported' do
        let(:feature_name) { Users::GroupCallout.feature_names.each_key.first.to_s }

        it 'creates a user group callout' do
          expect { resolve }.to change { Users::GroupCallout.count }.from(0).to(1)
        end

        it 'sets dismissed_at for the user group callout' do
          freeze_time do
            expect(resolve[:user_group_callout].dismissed_at).to eq(Time.current)
          end
        end

        it 'associates the callout with the correct group' do
          expect(resolve[:user_group_callout].group).to eq(group)
        end

        it 'associates the callout with the current user' do
          expect(resolve[:user_group_callout].user).to eq(current_user)
        end

        it 'has no errors' do
          expect(resolve[:errors]).to be_empty
        end

        context 'when callout already exists' do
          before do
            create(:group_callout, user: current_user, group: group, feature_name: feature_name)
          end

          it 'does not create a new callout' do
            expect { resolve }.not_to change { Users::GroupCallout.count }
          end

          it 'returns the existing callout' do
            existing_callout = Users::GroupCallout.find_by(user: current_user, group: group, feature_name: feature_name)
            expect(resolve[:user_group_callout]).to eq(existing_callout)
          end

          it 'has no errors' do
            expect(resolve[:errors]).to be_empty
          end
        end
      end
    end
  end
end
