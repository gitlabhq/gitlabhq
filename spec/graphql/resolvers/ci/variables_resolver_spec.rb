# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::VariablesResolver, feature_category: :ci_variables do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:args) { {} }
    let_it_be(:obj) { nil }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project) }

    let_it_be(:ci_instance_variables) do
      [
        create(:ci_instance_variable, key: 'a'),
        create(:ci_instance_variable, key: 'b')
      ]
    end

    let_it_be(:ci_group_variables) do
      [
        create(:ci_group_variable, group: group, key: 'a'),
        create(:ci_group_variable, group: group, key: 'b')
      ]
    end

    let_it_be(:ci_project_variables) do
      [
        create(:ci_variable, project: project, key: 'a'),
        create(:ci_variable, project: project, key: 'b')
      ]
    end

    subject(:resolve_variables) { resolve(described_class, obj: obj, ctx: { current_user: user }, args: args) }

    context 'when parent object is nil' do
      context 'when user is authorized', :enable_admin_mode do
        let_it_be(:user) { create(:admin) }

        it "returns the instance's variables" do
          expect(resolve_variables.items.to_a).to match_array(ci_instance_variables)
        end
      end

      context 'when user is not authorized' do
        it "returns nil" do
          expect(resolve_variables).to be_nil
        end
      end
    end

    context 'when parent object is a Group' do
      let_it_be(:obj) { group }

      it "returns the group's variables" do
        expect(resolve_variables.items.to_a).to match_array(ci_group_variables)
      end
    end

    context 'when parent object is a Project' do
      let_it_be(:obj) { project }

      it "returns the project's variables" do
        expect(resolve_variables.items.to_a).to match_array(ci_project_variables)
      end
    end
  end
end
