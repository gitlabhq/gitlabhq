# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::GroupReleasesResolver, feature_category: :release_orchestration do
  include GraphqlHelpers

  let_it_be(:today) { Time.now }
  let_it_be(:yesterday) { today - 1.day }
  let_it_be(:tomorrow) { today + 1.day }

  let_it_be(:group) { create(:group, :private) }
  let_it_be(:project) { create(:project, :private, namespace: group) }
  let_it_be(:release_v1) do
    create(:release, project: project, tag: 'v1.0.0', released_at: yesterday, created_at: tomorrow)
  end

  let_it_be(:release_v2) do
    create(:release, project: project, tag: 'v2.0.0', released_at: today, created_at: yesterday)
  end

  let_it_be(:release_v3) do
    create(:release, project: project, tag: 'v3.0.0', released_at: tomorrow, created_at: today)
  end

  let_it_be(:developer) { create(:user) }
  let_it_be(:public_user) { create(:user) }

  let(:args) { { sort: :released_at_desc } }
  let(:all_releases) { [release_v1, release_v2, release_v3] }

  before do
    group.add_member(developer, :owner)
    project.add_developer(developer)
  end

  describe '#resolve' do
    it_behaves_like 'releases and group releases resolver'
  end

  private

  def resolve_releases
    context = { current_user: current_user }
    resolve(described_class, obj: group, args: args, ctx: context, arg_style: :internal)
  end
end
