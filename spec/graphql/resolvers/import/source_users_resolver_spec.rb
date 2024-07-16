# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Import::SourceUsersResolver, feature_category: :importers do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:import_source_users) { create_list(:import_source_user, 3, namespace: group) }
  let(:args) { {} }
  let(:current_user) { user }

  before_all do
    group.add_owner(user)
  end

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::Import::SourceUserType.connection_type)
  end

  describe '#resolve' do
    it 'returns all import source users' do
      expect(resolve_import_source_users).to match_array(import_source_users)
    end

    context 'when user is not authorized' do
      let(:current_user) { create(:user)  }

      it { expect(resolve_import_source_users).to eq(nil) }
    end

    context 'when `importer_user_mapping` feature flag is diabled' do
      before do
        stub_feature_flags(importer_user_mapping: false)
      end

      it { expect(resolve_import_source_users).to be_empty }
    end

    describe 'arguments' do
      let(:args) { { search: 'search', statuses: ['AWAITING_APPROVAL'], sort: 'STATUS_ASC' } }

      it 'calls Import::SourceUsersFinder with the expected arguments' do
        expected_args = { search: 'search', statuses: [1], sort: :status_asc }

        expect_next_instance_of(::Import::SourceUsersFinder, group, current_user, expected_args) do |finder|
          expect(finder).to receive(:execute)
        end

        resolve_import_source_users
      end
    end
  end

  def resolve_import_source_users
    resolve(described_class, args: args, ctx: { current_user: current_user }, obj: group)
  end
end
