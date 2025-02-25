# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::WorkItems::UserWorkItemsResolver, feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group)         { create(:group) }
  let_it_be(:other_group)   { create(:group) }
  let_it_be(:project)       { create(:project, group: group) }
  let_it_be(:other_project) { create(:project, group: group) }

  let_it_be(:current_user)  { create(:user, developer_of: project) }

  let(:default_filter) { { created_before: 1.year.from_now } }

  let_it_be(:project_work_item1) do
    create(
      :work_item,
      project: project,
      state: :opened,
      created_at: 3.hours.ago,
      updated_at: 3.hours.ago,
      title: 'foo'
    )
  end

  let_it_be(:project_work_item2) do
    create(
      :work_item,
      project: project,
      state: :closed,
      created_at: 1.hour.ago,
      updated_at: 1.hour.ago,
      closed_at: 1.hour.ago,
      title: 'bar'
    )
  end

  let_it_be(:other_project_work_item1) do
    create(
      :work_item,
      project: other_project,
      state: :closed,
      created_at: 1.hour.ago,
      updated_at: 1.hour.ago,
      closed_at: 1.hour.ago,
      title: 'baz'
    )
  end

  let_it_be(:other_project_work_item2) do
    create(
      :work_item,
      project: other_project,
      confidential: true,
      title: 'Baz 2'
    )
  end

  let_it_be(:other_group_work_item1) do
    create(
      :work_item,
      :group_level,
      :epic,
      namespace: other_group,
      title: 'Baz 3'
    )
  end

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::WorkItemType.connection_type)
  end

  context "with project access" do
    describe '#resolve' do
      it 'finds only the items within the project we have access to' do
        expect(batch_sync { resolve_items.to_a }).to contain_exactly(project_work_item1, project_work_item2)
      end

      it 'respects the confidentiality of work items' do
        other_project.add_guest(current_user)

        expect(resolve_items).to contain_exactly(project_work_item1, project_work_item2, other_project_work_item1)
      end
    end
  end

  context "with group access" do
    before do
      stub_feature_flags(namespace_level_work_items: true, work_item_epics: true)
      stub_licensed_features(epics: true)
    end

    let_it_be(:developer) { create(:user, developer_of: group) }

    describe '#resolve' do
      it 'finds only the items within the group we have access to' do
        expect(batch_sync do
          resolve_items(default_filter, { current_user: developer }).to_a
        end).to contain_exactly(project_work_item1, project_work_item2, other_project_work_item1,
          other_project_work_item2)
      end

      # TODO: Enable this spec when the work items finder supports returning group level work items across groups
      it 'returns group level work items' do
        pending('changes in work items finder to support fetching work items at the group level cross group')

        other_group.add_developer(developer)

        expect(batch_sync do
          resolve_items(default_filter, { current_user: developer }).to_a
        end).to contain_exactly(project_work_item1, project_work_item2, other_project_work_item1,
          other_project_work_item2, other_group_work_item1)
      end
    end
  end

  describe '#resolve' do
    describe 'sorting' do
      context 'when sorting by created' do
        it 'sorts items ascending' do
          expect(resolve_items(default_filter.merge(sort: :created_asc)).to_a).to eq [project_work_item1,
            project_work_item2]
        end

        it 'sorts items descending' do
          expect(resolve_items(default_filter.merge(sort: :created_desc)).to_a).to eq [project_work_item2,
            project_work_item1]
        end
      end

      context 'when sorting by title' do
        it 'sorts items ascending' do
          expect(resolve_items(default_filter.merge(sort: :title_asc)).to_a).to eq [project_work_item2,
            project_work_item1]
        end

        it 'sorts items descending' do
          expect(resolve_items(default_filter.merge(sort: :title_desc)).to_a).to eq [project_work_item1,
            project_work_item2]
        end
      end
    end

    it 'raises an error if a filter is not provided' do
      expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError,
        'You must provide at least one filter argument for this query') do
        resolve_items({})
      end
    end
  end

  def resolve_items(args = default_filter, context = { current_user: current_user })
    resolve(described_class, args: args, ctx: context, arg_style: :internal)
  end
end
