# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::CustomEmoji::Destroy do
  include GraphqlHelpers
  let_it_be(:group) { create(:group) }
  let_it_be(:current_user) { create(:user) }
  let_it_be_with_reload(:custom_emoji) { create(:custom_emoji, group: group) }

  let(:args) { { id: custom_emoji.to_global_id } }
  let(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  context 'field tests' do
    subject { described_class }

    it { is_expected.to have_graphql_arguments(:clientMutationId, :id) }
    it { is_expected.to have_graphql_field(:custom_emoji) }
  end

  shared_examples 'does not delete custom emoji' do
    it 'raises exception' do
      expect { subject }
        .to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end
  end

  shared_examples 'deletes custom emoji' do
    it 'returns deleted custom emoji' do
      result = subject

      expect(result[:custom_emoji][:name]).to eq(custom_emoji.name)
    end
  end

  describe '#resolve' do
    subject { mutation.resolve(**args) }

    context 'when the user' do
      context 'has no permissions' do
        it_behaves_like 'does not delete custom emoji'
      end

      context 'when the user is developer and not the owner of custom emoji' do
        before do
          group.add_developer(current_user)
        end

        it_behaves_like 'does not delete custom emoji'
      end
    end

    context 'when user' do
      context 'is maintainer' do
        before do
          group.add_maintainer(current_user)
        end

        it_behaves_like 'deletes custom emoji'
      end

      context 'is owner' do
        before do
          group.add_owner(current_user)
        end

        it_behaves_like 'deletes custom emoji'
      end

      context 'is developer and creator of the emoji' do
        before do
          group.add_developer(current_user)
          custom_emoji.update_attribute(:creator, current_user)
        end

        it_behaves_like 'deletes custom emoji'
      end
    end
  end
end
