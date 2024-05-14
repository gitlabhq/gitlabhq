# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ReleasesResolver, feature_category: :release_orchestration do
  include GraphqlHelpers

  let_it_be(:today) { Time.now }
  let_it_be(:yesterday) { today - 1.day }
  let_it_be(:tomorrow) { today + 1.day }

  let_it_be(:project) { create(:project, :private) }
  let_it_be(:release_v1) { create(:release, project: project, tag: 'v1.0.0', released_at: yesterday, created_at: tomorrow) }
  let_it_be(:release_v2) { create(:release, project: project, tag: 'v2.0.0', released_at: today,     created_at: yesterday) }
  let_it_be(:release_v3) { create(:release, project: project, tag: 'v3.0.0', released_at: tomorrow,  created_at: today) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:public_user) { create(:user) }

  let(:args) { { sort: :released_at_desc } }
  let(:all_releases) { [release_v1, release_v2, release_v3] }

  describe '#resolve' do
    it_behaves_like 'releases and group releases resolver'

    describe 'when order_by is created_at' do
      let(:current_user) { developer }

      context 'with sort: desc' do
        let(:args) { { sort: :created_desc } }

        it 'returns the releases ordered by created_at in descending order' do
          expect(resolve_releases.to_a)
            .to match_array(all_releases)
            .and be_sorted(:created_at, :desc)
        end
      end

      context 'with sort: asc' do
        let(:args) { { sort: :created_asc } }

        it 'returns the releases ordered by created_at in ascending order' do
          expect(resolve_releases.to_a)
            .to match_array(all_releases)
            .and be_sorted(:created_at, :asc)
        end
      end
    end
  end

  private

  def resolve_releases
    context = { current_user: current_user }
    resolve(described_class, obj: project, args: args, ctx: context, arg_style: :internal)
  end
end
