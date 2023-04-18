# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ForkTargetsFinder do
  subject(:finder) { described_class.new(project, user) }

  let_it_be(:project) { create(:project, namespace: create(:group)) }
  let_it_be(:user) { create(:user) }
  let_it_be(:maintained_group) do
    create(:group).tap { |g| g.add_maintainer(user) }
  end

  let_it_be(:owned_group) do
    create(:group).tap { |g| g.add_owner(user) }
  end

  let_it_be(:developer_group) do
    create(:group, project_creation_level: ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS).tap do |g|
      g.add_developer(user)
    end
  end

  let_it_be(:reporter_group) do
    create(:group).tap { |g| g.add_reporter(user) }
  end

  let_it_be(:guest_group) do
    create(:group).tap { |g| g.add_guest(user) }
  end

  let_it_be(:shared_group_to_group_with_owner_access) do
    create(:group)
  end

  before do
    project.namespace.add_owner(user)
    create(:group_group_link, :maintainer,
      shared_with_group: owned_group,
      shared_group: shared_group_to_group_with_owner_access
    )
  end

  shared_examples 'returns namespaces and groups' do
    it 'returns all user manageable namespaces' do
      expect(finder.execute).to match_array([
        user.namespace,
        maintained_group,
        owned_group,
        project.namespace,
        developer_group,
        shared_group_to_group_with_owner_access
      ])
    end

    it 'returns only groups when only_groups option is passed' do
      expect(finder.execute(only_groups: true)).to match_array([
        maintained_group,
        owned_group,
        project.namespace,
        developer_group,
        shared_group_to_group_with_owner_access
      ])
    end

    it 'returns groups relation when only_groups option is passed' do
      expect(finder.execute(only_groups: true)).to include(a_kind_of(Group))
    end
  end

  describe '#execute' do
    it_behaves_like 'returns namespaces and groups'

    context 'when search is provided' do
      it 'filters the targets by the param' do
        expect(finder.execute(search: maintained_group.path)).to eq([maintained_group])
      end
    end
  end
end
