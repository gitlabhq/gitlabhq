# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::WorkItemsResolver, feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:reporter) { create(:user) }

  let_it_be(:group)         { create(:group) }
  let_it_be(:project)       { create(:project, group: group) }
  let_it_be(:other_project) { create(:project, group: group) }

  let_it_be(:item1) do
    create(
      :work_item,
      project: project,
      state: :opened,
      created_at: 3.hours.ago,
      updated_at: 3.hours.ago,
      start_date: 3.days.ago,
      due_date: 1.day.from_now
    )
  end

  let_it_be(:item2) do
    create(
      :work_item,
      project: project,
      state: :closed,
      title: 'foo',
      created_at: 1.hour.ago,
      updated_at: 1.hour.ago,
      closed_at: 1.hour.ago,
      start_date: 1.day.ago,
      due_date: 3.days.from_now
    )
  end

  let_it_be(:item3) do
    create(
      :work_item,
      project: other_project,
      state: :closed,
      title: 'foo',
      created_at: 1.hour.ago,
      updated_at: 1.hour.ago,
      closed_at: 1.hour.ago
    )
  end

  let_it_be(:item4) { create(:work_item) }

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::WorkItemType.connection_type)
  end

  context "with a project" do
    before_all do
      project.add_developer(current_user)
      project.add_reporter(reporter)
    end

    describe '#resolve' do
      it 'finds all items' do
        expect(resolve_items).to contain_exactly(item1, item2)
      end

      context 'when searching items' do
        it_behaves_like 'graphql query for searching issuables' do
          let_it_be(:parent) { project }
          let_it_be(:issuable1) { create(:work_item, project: project, title: 'first created') }
          let_it_be(:issuable2) { create(:work_item, project: project, title: 'second created', description: 'text 1') }
          let_it_be(:issuable3) { create(:work_item, project: project, title: 'third', description: 'text 2') }
          let_it_be(:issuable4) { create(:work_item, project: project) }

          let_it_be(:finder_class) { ::WorkItems::WorkItemsFinder }
          let_it_be(:optimization_param) { :attempt_project_search_optimizations }
        end
      end

      describe 'sorting' do
        context 'when sorting by created' do
          it 'sorts items ascending' do
            expect(resolve_items(sort: 'created_asc').to_a).to eq [item1, item2]
          end

          it 'sorts items descending' do
            expect(resolve_items(sort: 'created_desc').to_a).to eq [item2, item1]
          end
        end

        %w[start_date due_date].each do |field|
          it 'sorts items ascending' do
            expect(resolve_items(sort: "#{field}_asc").to_a).to eq [item1, item2]
          end

          it 'sorts items descending' do
            expect(resolve_items(sort: "#{field}_desc").to_a).to eq [item2, item1]
          end
        end

        context 'when sorting by title' do
          let_it_be(:project) { create(:project, :public) }
          let_it_be(:item1) { create(:work_item, project: project, title: 'foo') }
          let_it_be(:item2) { create(:work_item, project: project, title: 'bar') }
          let_it_be(:item3) { create(:work_item, project: project, title: 'baz') }
          let_it_be(:item4) { create(:work_item, project: project, title: 'Baz 2') }

          it 'sorts items ascending' do
            expect(resolve_items(sort: :title_asc).to_a).to eq [item2, item3, item4, item1]
          end

          it 'sorts items descending' do
            expect(resolve_items(sort: :title_desc).to_a).to eq [item1, item4, item3, item2]
          end
        end
      end

      it 'returns items user can see' do
        project.add_guest(current_user)

        create(:work_item, confidential: true)

        expect(resolve_items).to contain_exactly(item1, item2)
      end

      it 'batches queries that only include IIDs', :request_store do
        result = batch_sync(max_queries: 15) do
          [item1, item2]
            .map { |item| resolve_items(iid: item.iid.to_s) }
            .flat_map(&:to_a)
        end

        expect(result).to contain_exactly(item1, item2)
      end

      it 'finds a specific item with iids', :request_store do
        result = batch_sync(max_queries: 15) do
          resolve_items(iids: [item1.iid]).to_a
        end

        expect(result).to contain_exactly(item1)
      end

      it 'finds multiple items with iids' do
        create(:work_item, project: project, author: current_user)

        expect(batch_sync { resolve_items(iids: [item1.iid, item2.iid]).to_a })
          .to contain_exactly(item1, item2)
      end

      it 'finds only the items within the project we are looking at' do
        another_project = create(:project)
        iids = [item1, item2].map(&:iid)

        iids.each do |iid|
          create(:work_item, project: another_project, iid: iid)
        end

        expect(batch_sync { resolve_items(iids: iids).to_a }).to contain_exactly(item1, item2)
      end

      context 'with parent_ids filter' do
        shared_examples 'a parent_id filter' do |param_builder|
          context 'when converting global ids to work item ids' do
            let_it_be(:work_item1) { create(:work_item) }
            let_it_be(:work_item2) { create(:work_item) }

            let(:global_ids) { [work_item1.to_global_id, work_item2.to_global_id] }
            let(:context) { { arg_style: :internal_prepared } }

            it 'correctly processes global IDs and maps to work item model_ids' do
              expect(GitlabSchema).to receive(:parse_gids).with(global_ids, expected_type: ::WorkItem).and_call_original

              params = param_builder.call(parent_ids: global_ids.map(&:to_s))
              batch_sync { resolve_items(params, context) }
            end
          end
        end

        context 'when passed at the top level' do
          it_behaves_like 'a parent_id filter', ->(args) { args }
        end

        context 'when passed through the hierarchy_filters argument' do
          it_behaves_like 'a parent_id filter', ->(args) { { hierarchy_filters: args } }
        end
      end

      context 'with not parent_ids filter' do
        let_it_be(:work_item_without_parent) { create(:work_item, :issue, project: project) }
        let_it_be(:work_item_with_parent) { create(:work_item, :task, project: project) }
        let(:context) { { arg_style: :internal_prepared } }

        before do
          create(:parent_link, work_item_parent: work_item_without_parent, work_item: work_item_with_parent)
        end

        it 'filters by not parent ids' do
          items = resolve_items({ not: { parent_ids: [work_item_without_parent.to_global_id.to_s] } }, context)

          expect(items).not_to include(work_item_with_parent)
          expect(items).to include(work_item_without_parent)
        end
      end

      context 'with parent_wildcard_id filter' do
        let_it_be(:work_item_without_parent) { create(:work_item, :issue, project: project) }
        let_it_be(:work_item_with_parent) { create(:work_item, :task, project: project) }

        before do
          create(:parent_link, work_item_parent: work_item_without_parent, work_item: work_item_with_parent)
        end

        it 'returns work items with any parent' do
          items = resolve_items(parent_wildcard_id: 'ANY')

          expect(items).to include(work_item_with_parent)
          expect(items).not_to include(work_item_without_parent)
        end

        it 'returns work items with no parent' do
          items = resolve_items(parent_wildcard_id: 'NONE')

          expect(items).to include(work_item_without_parent)
          expect(items).not_to include(work_item_with_parent)
        end

        context 'with hierarchy_filters argument' do
          it 'returns work items with any parent' do
            items = resolve_items(hierarchy_filters: { parent_wildcard_id: 'ANY' })

            expect(items).to include(work_item_with_parent)
            expect(items).not_to include(work_item_without_parent)
          end

          it 'returns work items with no parent' do
            items = resolve_items(hierarchy_filters: { parent_wildcard_id: 'NONE' })

            expect(items).to include(work_item_without_parent)
            expect(items).not_to include(work_item_with_parent)
          end

          context 'when parent_wildcard_id is passed with hierarchy_filters' do
            it 'generates a mutually exclusive argument error' do
              expect_graphql_error_to_be_created(GraphQL::Schema::Validator::ValidationFailedError,
                'Only one of [hierarchyFilters, parentWildcardId] arguments is allowed at the same time.') do
                resolve_items(parent_wildcard_id: 'ANY', hierarchy_filters: { parent_wildcard_id: 'ANY' })
              end
            end
          end

          context 'when parent_wildcard_id is passed with parent_ids' do
            it 'generates a mutually exclusive argument error' do
              expect_graphql_error_to_be_created(GraphQL::Schema::Validator::ValidationFailedError,
                'Only one of [hierarchyFilters, parentIds] arguments is allowed at the same time.') do
                resolve_items(
                  parent_ids: [work_item_with_parent.to_global_id],
                  hierarchy_filters: { parent_wildcard_id: 'ANY' }
                )
              end
            end
          end
        end
      end

      describe 'filter by release' do
        let_it_be(:milestone1) { create(:milestone, project: project, start_date: 1.day.from_now, title: 'Version 1') }
        let_it_be(:milestone2) { create(:milestone, project: project, start_date: 1.day.from_now, title: 'Version 2') }
        let_it_be(:milestone3) { create(:milestone, project: project, start_date: 1.day.from_now, title: 'Version 3') }
        let_it_be(:release1) { create(:release, tag: 'v1.0', milestones: [milestone1], project: project) }
        let_it_be(:release2) { create(:release, tag: 'v2.0', milestones: [milestone2], project: project) }
        let_it_be(:release3) { create(:release, tag: 'v3.0', milestones: [milestone3], project: project) }
        let_it_be(:release_work_item_issue1) { create(:work_item, :issue, project: project, milestone: milestone1) }
        let_it_be(:release_work_item_issue2) { create(:work_item, :issue, project: project, milestone: milestone2) }
        let_it_be(:release_work_item_issue3) { create(:work_item, :issue, project: project, milestone: milestone3) }

        describe 'filter by release_tag' do
          it 'returns all issues associated with the specified tags' do
            expect(resolve_items(release_tag: [release1.tag,
              release3.tag])).to contain_exactly(release_work_item_issue1, release_work_item_issue3)
          end

          context 'when release_tag_wildcard_id is also provided' do
            it 'generates a mutually exclusive argument error' do
              expect_graphql_error_to_be_created(GraphQL::Schema::Validator::ValidationFailedError,
                'Only one of [releaseTag, releaseTagWildcardId] arguments is allowed at the same time.') do
                resolve_items(release_tag: [release1.tag], release_tag_wildcard_id: 'ANY')
              end
            end
          end
        end

        describe 'filter by negated release_tag' do
          it 'returns all issues not associated with the specified tags' do
            expect(resolve_items(not: { release_tag: [release1.tag,
              release3.tag] })).to contain_exactly(release_work_item_issue2)
          end
        end

        describe 'filter by release_tag_wildcard_id' do
          subject { resolve_items(release_tag_wildcard_id: wildcard_id) }

          context 'when filtering by ANY' do
            let(:wildcard_id) { 'ANY' }

            it 'returns all work items that have any release tag' do
              is_expected.to contain_exactly(release_work_item_issue1, release_work_item_issue2,
                release_work_item_issue3)
            end
          end

          context 'when filtering by NONE' do
            let(:wildcard_id) { 'NONE' }

            it 'returns only work items that have no release tag' do
              is_expected.to contain_exactly(item1, item2)
            end
          end
        end
      end

      describe 'filtering by crm' do
        let_it_be(:crm_organization) { create(:crm_organization, group: group) }
        let_it_be(:contact1) { create(:contact, group: group, organization: crm_organization) }
        let_it_be(:contact2) { create(:contact, group: group, organization: crm_organization) }
        let_it_be(:contact3) { create(:contact, group: group) }
        let_it_be(:crm_work_item_issue1) { create(:work_item, :issue, project: project) }
        let_it_be(:crm_work_item_issue2) { create(:work_item, :issue, project: project) }
        let_it_be(:crm_work_item_issue3) { create(:work_item, :issue, project: project) }

        before_all do
          group.add_developer(current_user)

          create(:issue_customer_relations_contact, issue: crm_work_item_issue1, contact: contact1)
          create(:issue_customer_relations_contact, issue: crm_work_item_issue2, contact: contact2)
          create(:issue_customer_relations_contact, issue: crm_work_item_issue3, contact: contact3)
        end

        context 'when filtering by contact' do
          it 'returns only the issues for the contact' do
            expect(resolve_items({ crm_contact_id: contact1.id })).to contain_exactly(crm_work_item_issue1)
          end
        end

        context 'when filtering by crm_organization' do
          it 'returns only the issues for the organization' do
            expect(resolve_items({ crm_organization_id: crm_organization.id })).to contain_exactly(crm_work_item_issue1,
              crm_work_item_issue2)
          end
        end
      end

      describe 'filtering by ids' do
        let(:context) { { arg_style: :internal_prepared } }

        it 'returns only the work items matching the ids filter' do
          expect(resolve_items({ ids: [item1.to_gid.to_s] }, context)).to contain_exactly(item1)
        end
      end
    end
  end

  context "when passing a non existent, batch loaded project" do
    let!(:project) do
      BatchLoader::GraphQL.for("non-existent-path").batch do |_fake_paths, loader, _|
        loader.call("non-existent-path", nil)
      end
    end

    it "returns nil without breaking" do
      expect(resolve_items(iids: ["don't", "break"])).to be_empty
    end
  end

  def resolve_items(args = {}, context = {})
    context[:current_user] = current_user
    arg_style = context[:arg_style] ||= :internal

    resolve(described_class, obj: project, args: args, ctx: context, arg_style: arg_style)
  end
end
