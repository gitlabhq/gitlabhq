# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::GroupLabelsResolver do
  include GraphqlHelpers

  using RSpec::Parameterized::TableSyntax

  let_it_be(:current_user) { create(:user) }
  let_it_be(:organization) { create(:organization) }
  let_it_be(:group, reload: true) { create(:group, :private, organization: organization) }
  let_it_be(:subgroup, reload: true) { create(:group, :private, parent: group, organization: organization) }
  let_it_be(:sub_subgroup, reload: true) { create(:group, :private, parent: subgroup, organization: organization) }
  let_it_be(:project, reload: true) { create(:project, :private, group: sub_subgroup, organization: organization) }
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
      it 'generates an error' do
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
          resolve_labels(subgroup)
        end
      end
    end

    context 'with authorized user' do
      it 'does not raise error' do
        group.add_guest(current_user)

        expect(resolve_labels(subgroup)).to be_instance_of(Gitlab::Graphql::Pagination::Keyset::Connection)
      end
    end

    context 'without parent' do
      it 'returns no labels' do
        expect(resolve_labels(nil)).to be_empty
      end
    end

    describe 'association preloading', :saas do
      let(:params) do
        {
          include_ancestor_groups: true,
          include_descendant_groups: true,
          only_group_labels: false
        }
      end

      before do
        group.add_developer(current_user)

        # warmup
        resolve_labels(group, params).to_a
      end

      it 'prevents N+1 queries' do
        control = Gitlab::SafeRequestStore.ensure_request_store do
          ActiveRecord::QueryRecorder.new { resolve_labels(group, params).to_a }
        end

        another_project = create(:project, :private, group: sub_subgroup, organization: organization)
        another_subgroup = create(:group, :private, parent: group, organization: organization)
        create(:label, project: another_project, name: 'another project feature')
        create(:group_label, group: another_subgroup, name: 'another group feature')

        expect do
          Gitlab::SafeRequestStore.ensure_request_store do
            resolve_labels(group, params).to_a
          end
        end.not_to exceed_query_limit(control)
      end
    end

    context 'at group level' do
      before_all do
        group.add_developer(current_user)
      end

      # because :include_ancestor_groups, :include_descendant_groups, :only_group_labels default to false
      # the `nil` value would be equivalent to passing in `false` so just check for `nil` option
      where(:include_ancestor_groups, :include_descendant_groups, :only_group_labels, :search_term, :test) do
        nil     |  nil     | nil    | nil   | -> { expect(subject).to contain_exactly(subgroup_label1, subgroup_label2) }
        nil     |  nil     | true   | nil   | -> { expect(subject).to contain_exactly(subgroup_label1, subgroup_label2) }
        nil     |  true    | nil    | nil   | -> { expect(subject).to contain_exactly(subgroup_label1, subgroup_label2, sub_subgroup_label1, sub_subgroup_label2, label1, label2) }
        nil     |  true    | true   | nil   | -> { expect(subject).to contain_exactly(subgroup_label1, subgroup_label2, sub_subgroup_label1, sub_subgroup_label2) }
        true    |  nil     | nil    | nil   | -> { expect(subject).to contain_exactly(group_label1, group_label2, subgroup_label1, subgroup_label2) }
        true    |  nil     | true   | nil   | -> { expect(subject).to contain_exactly(group_label1, group_label2, subgroup_label1, subgroup_label2) }
        true    |  true    | nil    | nil   | -> { expect(subject).to contain_exactly(group_label1, group_label2, subgroup_label1, subgroup_label2, sub_subgroup_label1, sub_subgroup_label2, label1, label2) }
        true    |  true    | true   | nil   | -> { expect(subject).to contain_exactly(group_label1, group_label2, subgroup_label1, subgroup_label2, sub_subgroup_label1, sub_subgroup_label2) }

        nil     |  nil     | nil    | 'new'   | -> { expect(subject).to contain_exactly(subgroup_label2) }
        nil     |  nil     | true   | 'new'   | -> { expect(subject).to contain_exactly(subgroup_label2) }
        nil     |  true    | nil    | 'new'   | -> { expect(subject).to contain_exactly(subgroup_label2, sub_subgroup_label2, label2) }
        nil     |  true    | true   | 'new'   | -> { expect(subject).to contain_exactly(subgroup_label2, sub_subgroup_label2) }
        true    |  nil     | nil    | 'new'   | -> { expect(subject).to contain_exactly(group_label2, subgroup_label2) }
        true    |  nil     | true   | 'new'   | -> { expect(subject).to contain_exactly(group_label2, subgroup_label2) }
        true    |  true    | nil    | 'new'   | -> { expect(subject).to contain_exactly(group_label2, subgroup_label2, sub_subgroup_label2, label2) }
        true    |  true    | true   | 'new'   | -> { expect(subject).to contain_exactly(group_label2, subgroup_label2, sub_subgroup_label2) }
      end

      with_them do
        let(:params) do
          {
            include_ancestor_groups: include_ancestor_groups,
            include_descendant_groups: include_descendant_groups,
            only_group_labels: only_group_labels,
            search_term: search_term
          }
        end

        subject { resolve_labels(subgroup, params) }

        it { self.instance_exec(&test) }
      end
    end
  end

  def resolve_labels(parent, args = {}, context = { current_user: current_user })
    resolve(described_class, obj: parent, args: args, ctx: context)
  end
end
