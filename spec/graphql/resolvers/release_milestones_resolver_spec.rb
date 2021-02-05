# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ReleaseMilestonesResolver do
  include GraphqlHelpers

  let_it_be(:release) { create(:release, :with_milestones, milestones_count: 2) }

  let(:resolved) do
    resolve(described_class, obj: release)
  end

  describe '#resolve' do
    it "uses offset-pagination" do
      expect(resolved).to be_a(::Gitlab::Graphql::Pagination::OffsetPaginatedRelation)
    end

    it "includes the release's milestones in the returned OffsetActiveRecordRelationConnection" do
      expect(resolved.to_a).to eq(release.milestones.order_by_dates_and_title)
    end
  end
end
