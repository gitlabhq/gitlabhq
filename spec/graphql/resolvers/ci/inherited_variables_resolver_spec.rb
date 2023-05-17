# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::InheritedVariablesResolver, feature_category: :secrets_management do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: group) }
    let_it_be(:project) { create(:project, group: subgroup) }
    let_it_be(:project_without_group) { create(:project) }

    let_it_be(:inherited_ci_variables) do
      [
        create(:ci_group_variable, group: group, key: 'GROUP_VAR_A'),
        create(:ci_group_variable, group: subgroup, key: 'SUBGROUP_VAR_B')
      ]
    end

    subject(:resolve_variables) { resolve(described_class, obj: obj, ctx: { current_user: user }, args: {}) }

    context 'when project does not have a group' do
      let_it_be(:obj) { project_without_group }

      it 'returns an empty array' do
        expect(resolve_variables.items.to_a).to match_array([])
      end
    end

    context 'when project belongs to a group' do
      let_it_be(:obj) { project }

      it 'returns variables from parent group and ancestors' do
        expect(resolve_variables.items.to_a).to match_array(inherited_ci_variables)
      end
    end
  end
end
