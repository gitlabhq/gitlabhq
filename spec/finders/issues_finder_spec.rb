# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuesFinder, feature_category: :team_planning do
  include_context 'Issues or WorkItems Finder context', :issue

  it_behaves_like 'issues or work items finder', :issue, '{Issues|WorkItems}Finder#execute context'

  context 'when filtering by author username' do
    let_it_be(:issuable_parent) { create(:project) }
    let_it_be(:issuable_attributes) { { project: issuable_parent } }
    let_it_be(:issuable_factory) { :issue }
    let_it_be(:factory_params) { [] }

    let(:search_params) { { project_id: issuable_parent.id } }

    it_behaves_like 'filterable by group handle for', :author
    it_behaves_like 'filterable by group handle for', :assignees
  end

  context 'when filtering by group_id' do
    include_context '{Issues|WorkItems}Finder#execute context', :issue

    let(:params) { { group_id: group.id } }
    let(:scope) { 'all' }

    context 'when include_subgroup param not set' do
      it 'returns all group items' do
        expect(items).to contain_exactly(item1, item5)
      end

      context 'when projects outside the group are passed' do
        let(:params) { { group_id: group.id, projects: [project2.id] } }

        it 'returns no items' do
          expect(items).to be_empty
        end
      end

      context 'when projects of the group are passed' do
        let(:params) { { group_id: group.id, projects: [project1.id] } }

        it 'returns the item within the group and projects' do
          expect(items).to contain_exactly(item1, item5)
        end
      end

      context 'when projects of the group are passed as a subquery' do
        let(:params) { { group_id: group.id, projects: Project.id_in(project1.id) } }

        it 'returns the item within the group and projects' do
          expect(items).to contain_exactly(item1, item5)
        end
      end

      context 'when release_tag is passed as a parameter' do
        let(:params) { { group_id: group.id, release_tag: 'dne-release-tag' } }

        it 'ignores the release_tag parameter' do
          expect(items).to contain_exactly(item1, item5)
        end
      end
    end

    context 'when include_subgroup param is true' do
      before do
        params[:include_subgroups] = true
      end

      it 'returns all group and subgroup items' do
        expect(items).to contain_exactly(item1, item4, item5)
      end

      context 'when mixed projects are passed' do
        let(:params) { { group_id: group.id, projects: [project2.id, project3.id] } }

        it 'returns the item within the group and projects' do
          expect(items).to contain_exactly(item4)
        end
      end
    end
  end

  describe 'namespace_traversal_ids filtering optimization' do
    it_behaves_like 'issues or work items finder with namespace_traversal_ids filtering',
      :issue, include_subgroups_param: :include_subgroups
  end

  context 'when filtering by a date' do
    let_it_be(:item_due_2_weeks_ago) { create(:issue, project: project1, due_date: 2.weeks.ago) }
    let_it_be(:item_due_yesterday) { create(:issue, project: project1, due_date: 1.day.ago) }
    let_it_be(:item_due_today) { create(:issue, project: project1, due_date: Date.current) }
    let_it_be(:item_due_tomorrow) { create(:issue, project: project1, due_date: 1.day.from_now) }
    let_it_be(:item_due_in_1_week) { create(:issue, project: project1, due_date: 1.week.from_now) }
    let(:scope) { 'all' }

    context 'when filtering by due_before' do
      include_context '{Issues|WorkItems}Finder#execute context', :issue

      let(:params) { { due_before: Date.current } }

      it 'returns relevant issues' do
        expect(items).to contain_exactly(item_due_2_weeks_ago, item_due_yesterday)
      end
    end

    context 'when filtering by due_after' do
      include_context '{Issues|WorkItems}Finder#execute context', :issue

      let(:params) { { due_after: Date.current } }

      it 'returns relevant issues' do
        expect(items).to contain_exactly(item_due_today, item_due_tomorrow, item_due_in_1_week)
      end
    end
  end

  describe 'filtering by service desk (author_username)' do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:support_bot) { create(:support_bot) }
    let_it_be(:user) { create(:user) }
    let_it_be(:service_desk_issue) { create(:issue, project: project, author: support_bot) }
    let_it_be(:regular_issue) { create(:issue, project: project, author: user) }
    let_it_be(:ticket) { create(:work_item, :ticket, project: project, author: user) }

    context 'when author_username matches support bot' do
      let(:params) { { project_id: project.id, author_username: support_bot.username } }

      subject(:items) { described_class.new(user, params).execute }

      it 'returns service desk issues and tickets' do
        expect(items).to contain_exactly(service_desk_issue, Issue.find(ticket.id))
      end
    end

    context 'when author_username does not match support bot' do
      let(:params) { { project_id: project.id, author_username: user.username } }

      subject(:items) { described_class.new(user, params).execute }

      it 'filters by author username normally' do
        expect(items).to contain_exactly(regular_issue, Issue.find(ticket.id))
      end
    end

    context 'with organization-specific support bot' do
      let_it_be(:organization) { create(:organization) }
      let_it_be(:org_support_bot) { Users::Internal.in_organization(organization).support_bot }
      let_it_be(:org_service_desk_issue) { create(:issue, project: project, author: org_support_bot) }

      let(:params) { { project_id: project.id, author_username: org_support_bot.username } }

      subject(:items) { described_class.new(user, params).execute }

      it 'returns service desk issues for organization-specific support bot' do
        expect(items).to include(org_service_desk_issue)
      end
    end
  end
end
