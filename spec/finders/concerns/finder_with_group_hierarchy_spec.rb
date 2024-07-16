# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FinderWithGroupHierarchy do
  let(:finder_class) do
    Class.new do
      include FinderWithGroupHierarchy
      include Gitlab::Utils::StrongMemoize

      def initialize(current_user, params = {})
        @current_user = current_user
        @params = params
      end

      def execute(skip_authorization: false)
        @skip_authorization = skip_authorization

        item_ids
      end

      # normally an array of item ids would be returned,
      # however for this spec just return the group ids
      def item_ids
        group? ? group_ids_for(group) : []
      end

      private

      attr_reader :current_user, :params, :skip_authorization

      def read_permission
        :read_label
      end
    end
  end

  let_it_be(:organization) { create(:organization) }
  let_it_be(:parent_group) { create(:group, organization: organization) }
  let_it_be(:group) { create(:group, parent: parent_group, organization: organization) }
  let_it_be(:private_group) { create(:group, :private, organization: organization) }
  let_it_be(:private_subgroup) { create(:group, :private, parent: private_group, organization: organization) }

  let_it_be(:user) { create(:user) }

  context 'when specifying group' do
    it 'returns only the group by default' do
      finder = finder_class.new(user, group: group)

      expect(finder.execute).to match_array([group.id])
    end
  end

  context 'when specifying group_id' do
    it 'returns only the group by default' do
      finder = finder_class.new(user, group_id: group.id)

      expect(finder.execute).to match_array([group.id])
    end
  end

  context 'when including items from group ancestors' do
    before do
      private_subgroup.add_developer(user)
    end

    it 'returns group and its ancestors' do
      private_group.add_developer(user)

      finder = finder_class.new(user, group: private_subgroup, include_ancestor_groups: true)

      expect(finder.execute).to match_array([private_group.id, private_subgroup.id])
    end

    it 'ignores groups which user can not read' do
      finder = finder_class.new(user, group: private_subgroup, include_ancestor_groups: true)

      expect(finder.execute).to match_array([private_subgroup.id])
    end

    it 'returns them all when skip_authorization is true' do
      finder = finder_class.new(user, group: private_subgroup, include_ancestor_groups: true)

      expect(finder.execute(skip_authorization: true)).to match_array([private_group.id, private_subgroup.id])
    end
  end

  context 'when including items from group descendants' do
    before do
      private_subgroup.add_developer(user)
    end

    it 'returns items from group and its descendants' do
      private_group.add_developer(user)

      finder = finder_class.new(user, group: private_group, include_descendant_groups: true)

      expect(finder.execute).to match_array([private_group.id, private_subgroup.id])
    end

    it 'ignores items from groups which user can not read' do
      finder = finder_class.new(user, group: private_group, include_descendant_groups: true)

      expect(finder.execute).to match_array([private_subgroup.id])
    end

    it 'returns them all when skip_authorization is true' do
      finder = finder_class.new(user, group: private_group, include_descendant_groups: true)

      expect(finder.execute(skip_authorization: true)).to match_array([private_group.id, private_subgroup.id])
    end
  end

  context 'with N+1 query check' do
    def run_query(group)
      finder_class
        .new(user, group: group, include_descendant_groups: true)
        .execute
        .to_a

      RequestStore.clear!
    end

    it 'does not produce N+1 query', :request_store do
      private_group.add_developer(user)

      run_query(private_subgroup) # warmup
      control = ActiveRecord::QueryRecorder.new { run_query(private_subgroup) }

      expect { run_query(private_group) }.not_to exceed_query_limit(control)
    end
  end
end
