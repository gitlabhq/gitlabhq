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

    context 'when `bulk_import_user_mapping` feature flag is diabled' do
      before do
        stub_feature_flags(bulk_import_user_mapping: false)
      end

      it { expect(resolve_import_source_users).to be_empty }
    end
  end

  def resolve_import_source_users
    resolve(described_class, args: args, ctx: { current_user: current_user }, obj: group)
  end
end
