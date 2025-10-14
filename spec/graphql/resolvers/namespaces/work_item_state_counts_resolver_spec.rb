# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Namespaces::WorkItemStateCountsResolver, feature_category: :team_planning do
  include GraphqlHelpers

  def resolve_items(obj, args = {})
    resolve(described_class, obj: obj, args: args, ctx: {}, arg_style: :internal)
  end

  context 'on a group namespace' do
    let_it_be(:namespace) { create(:group) }

    let(:wi_count_data) { instance_double(Gitlab::IssuablesCountForState, all: 2, opened: 2, closed: 0) }

    it 'does not fast fail when exclude_group_work_items is true' do
      expect(Gitlab::IssuablesCountForState).to receive(:new).with(
        anything,
        namespace,
        hash_including(
          fast_fail: false,
          store_in_redis_cache: true
        )
      ).and_return(wi_count_data)

      expect(resolve_items(namespace, { exclude_group_work_items: true })).to eq(wi_count_data)
    end

    it 'fast fails when exclude_group_work_items is not passed' do
      expect(Gitlab::IssuablesCountForState).to receive(:new).with(
        anything,
        namespace,
        hash_including(
          fast_fail: true,
          store_in_redis_cache: true
        )
      ).and_return(wi_count_data)

      expect(resolve_items(namespace)).to eq(wi_count_data)
    end
  end
end
