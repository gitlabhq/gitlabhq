# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::LabelsResolver do
  include GraphqlHelpers

  using RSpec::Parameterized::TableSyntax

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group, reload: true) { create(:group, :private) }
  let_it_be(:subgroup, reload: true) { create(:group, :private, parent: group) }
  let_it_be(:sub_subgroup, reload: true) { create(:group, :private, parent: subgroup) }
  let_it_be(:project, reload: true) { create(:project, :private, group: subgroup) }
  let_it_be(:label1) { create(:label, project: project, name: 'project feature') }
  let_it_be(:label2) { create(:label, project: project, name: 'new project feature') }
  let_it_be(:group_label1) { create(:group_label, group: group, name: 'group feature') }
  let_it_be(:group_label2) { create(:group_label, group: group, name: 'new group feature') }
  let_it_be(:subgroup_label1) { create(:group_label, group: subgroup, name: 'subgroup feature') }
  let_it_be(:subgroup_label2) { create(:group_label, group: subgroup, name: 'new subgroup feature') }
  let_it_be(:sub_subgroup_label1) { create(:group_label, group: sub_subgroup, name: 'sub_subgroup feature') }
  let_it_be(:sub_subgroup_label2) { create(:group_label, group: sub_subgroup, name: 'new sub_subgroup feature') }

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::LabelType.connection_type)
  end

  describe '#resolve' do
    context 'with unauthorized user' do
      it 'returns no labels' do
        expect { resolve_labels(project) }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'with authorized user' do
      it 'returns no labels' do
        group.add_guest(current_user)

        expect { resolve_labels(project) }.not_to raise_error
      end
    end

    context 'without parent' do
      it 'returns no labels' do
        expect(resolve_labels(nil)).to be_empty
      end
    end

    context 'with a parent project' do
      before_all do
        group.add_developer(current_user)
      end

      # the expected result is wrapped in a lambda to get around the phase restrictions of RSpec::Parameterized
      where(:include_ancestor_groups, :search_term, :expected_labels) do
        nil   | nil   | -> { [label1, label2, subgroup_label1, subgroup_label2] }
        false | nil   | -> { [label1, label2, subgroup_label1, subgroup_label2] }
        true  | nil   | -> { [label1, label2, group_label1, group_label2, subgroup_label1, subgroup_label2] }
        nil   | 'new' | -> { [label2, subgroup_label2] }
        false | 'new' | -> { [label2, subgroup_label2] }
        true  | 'new' | -> { [label2, group_label2, subgroup_label2] }
      end

      with_them do
        let(:params) do
          {
            include_ancestor_groups: include_ancestor_groups,
            search_term: search_term
          }
        end

        subject { resolve_labels(project, params) }

        specify { expect(subject).to match_array(instance_exec(&expected_labels)) }
      end
    end
  end

  def resolve_labels(parent, args = {}, context = { current_user: current_user })
    resolve(described_class, obj: parent, args: args, ctx: context)
  end
end
