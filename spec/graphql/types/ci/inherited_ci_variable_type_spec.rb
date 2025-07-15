# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::InheritedCiVariableType, feature_category: :ci_variables do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:variable) { create(:ci_group_variable, group: group) }

  specify do
    expect(described_class).to have_graphql_fields(
      :id,
      :key,
      :description,
      :raw,
      :environment_scope,
      :protected,
      :masked,
      :hidden,
      :group_name,
      :group_ci_cd_settings_path,
      :variable_type
    ).at_least
  end

  describe '#group_ci_cd_settings_path' do
    subject(:settings_path) { resolve_field(:group_ci_cd_settings_path, variable, current_user: user) }

    context 'when user has admin_cicd_variables permission' do
      before_all do
        group.add_owner(user)
      end

      it 'returns the group CI/CD settings path' do
        expected_path = Gitlab::Routing.url_helpers.group_settings_ci_cd_path(group)
        expect(settings_path).to eq(expected_path)
      end
    end

    context 'when user lacks admin_cicd_variables permission' do
      before_all do
        group.add_developer(user)
      end

      it 'returns nil' do
        expect(settings_path).to be_nil
      end
    end

    context 'when user is not a member of the group' do
      it 'returns nil' do
        expect(settings_path).to be_nil
      end
    end
  end
end
