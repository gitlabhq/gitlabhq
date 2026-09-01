# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuesFinder, feature_category: :team_planning do
  include_context 'Issues or WorkItems Finder context', :issue

  it_behaves_like 'issues or work items finder', :issue, '{Issues|WorkItems}Finder#execute context'

  context 'when filtering by author username' do
    let_it_be(:issuable_parent, freeze: false) { create(:project) }
    let_it_be(:issuable_attributes, freeze: false) { { project: issuable_parent } }
    let_it_be(:issuable_factory, freeze: false) { :issue }
    let_it_be(:factory_params, freeze: false) { [] }

    let(:search_params) { { project_id: issuable_parent.id } }

    it_behaves_like 'filterable by group handle for', :author
    it_behaves_like 'filterable by group handle for', :assignees
  end

  describe 'label filtering without a project or group scope' do
    let_it_be(:assignee, freeze: false) { create(:user) }
    let_it_be(:project, freeze: false) { create(:project, :public) }
    let_it_be(:other_project, freeze: false) { create(:project, :public) }
    let_it_be(:label, freeze: false) { create(:label, project: project, title: 'shared-title') }
    let_it_be(:same_title_label, freeze: false) { create(:label, project: other_project, title: 'shared-title') }
    let_it_be(:matching_issue, freeze: false) do
      create(:labeled_issue, project: project, assignees: [assignee], labels: [label])
    end

    let_it_be(:other_project_issue, freeze: false) do
      create(:labeled_issue, project: other_project, assignees: [assignee], labels: [same_title_label])
    end

    let_it_be(:excluded_label, freeze: false) { create(:label, project: project, title: 'excluded') }
    let_it_be(:excluded_issue, freeze: false) do
      create(:labeled_issue, project: project, assignees: [assignee], labels: [label, excluded_label])
    end

    let_it_be(:unlabeled_issue, freeze: false) { create(:issue, project: project, assignees: [assignee]) }
    let_it_be(:unassigned_issue, freeze: false) { create(:labeled_issue, project: project, labels: [label]) }

    let(:params) { { assignee_id: assignee.id, label_name: label.title } }

    it 'matches the same-titled label in every project, with and without the CTE fence', :aggregate_failures do
      expect(described_class.new(assignee, params).execute)
        .to contain_exactly(matching_issue, other_project_issue, excluded_issue)

      stub_feature_flags(use_cte_for_label_filter: false)

      expect(described_class.new(assignee, params).execute)
        .to contain_exactly(matching_issue, other_project_issue, excluded_issue)
    end

    it 'still applies negated label filtering, with and without the CTE fence', :aggregate_failures do
      negated = params.merge(not: { label_name: excluded_label.title })

      expect(described_class.new(assignee, negated).execute)
        .to contain_exactly(matching_issue, other_project_issue)

      stub_feature_flags(use_cte_for_label_filter: false)

      expect(described_class.new(assignee, negated).execute)
        .to contain_exactly(matching_issue, other_project_issue)
    end

    it 'counts by state through the fence', :aggregate_failures do
      counts = described_class.new(assignee, params).count_by_state

      expect(counts[:all]).to eq(3)
      expect(counts[:opened]).to eq(3)
    end

    it 'applies the label filter outside a materialized CTE', :aggregate_failures do
      sql = described_class.new(assignee, params).execute.to_sql

      expect(sql.scan('AS MATERIALIZED').size).to eq(1)
      expect(sql.split('"filtered_issuables" AS MATERIALIZED').last).to include('label_links')
    end

    it 'fences only a query bounded by a specific user', :aggregate_failures do
      fenced = ->(extra) do
        described_class
          .new(assignee, { label_name: label.title }.merge(extra))
          .execute.to_sql.include?('filtered_issuables')
      end

      expect(fenced.call(assignee_id: assignee.id)).to be(true)
      expect(fenced.call(assignee_username: assignee.username)).to be(true)
      expect(fenced.call(author_id: assignee.id)).to be(true)
      expect(fenced.call(author_username: assignee.username)).to be(true)

      expect(fenced.call(assignee_id: 'None')).to be(false)
      expect(fenced.call(assignee_id: 'Any')).to be(false)
      expect(fenced.call(assignee_id: assignee.id, project_id: project.id)).to be(false)
      expect(fenced.call({})).to be(false)

      expect(fenced.call(assignee_id: assignee.id, sort: 'priority')).to be(false)
      expect(fenced.call(assignee_id: assignee.id, sort: 'label_priority')).to be(false)
      expect(fenced.call(assignee_id: assignee.id, sort: 'popularity')).to be(false)
      expect(fenced.call(assignee_id: assignee.id, sort: 'upvotes_desc')).to be(false)
      expect(fenced.call(assignee_id: assignee.id, sort: 'downvotes_desc')).to be(false)
    end

    it 'keeps every filter applied when sorting by priority' do
      priority_params = params.merge(sort: 'priority')

      expect(described_class.new(assignee, priority_params).execute)
        .to contain_exactly(matching_issue, other_project_issue, excluded_issue)
    end
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
    let_it_be(:item_due_2_weeks_ago, freeze: false) { create(:issue, project: project1, due_date: 2.weeks.ago) }
    let_it_be(:item_due_yesterday, freeze: false) { create(:issue, project: project1, due_date: 1.day.ago) }
    let_it_be(:item_due_today, freeze: false) { create(:issue, project: project1, due_date: Date.current) }
    let_it_be(:item_due_tomorrow, freeze: false) { create(:issue, project: project1, due_date: 1.day.from_now) }
    let_it_be(:item_due_in_1_week, freeze: false) { create(:issue, project: project1, due_date: 1.week.from_now) }
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
    let_it_be(:project, freeze: false) { create(:project, :public) }
    let_it_be(:support_bot, freeze: false) { create(:support_bot) }
    let_it_be(:user, freeze: false) { create(:user) }
    let_it_be(:service_desk_issue, freeze: false) { create(:issue, project: project, author: support_bot) }
    let_it_be(:regular_issue, freeze: false) { create(:issue, project: project, author: user) }
    let_it_be(:ticket, freeze: false) { create(:work_item, :ticket, project: project, author: user) }

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
      let_it_be(:organization, freeze: false) { create(:organization) }
      let_it_be(:org_support_bot, freeze: false) { Users::Internal.in_organization(organization).support_bot }
      let_it_be(:org_service_desk_issue, freeze: false) { create(:issue, project: project, author: org_support_bot) }

      let(:params) { { project_id: project.id, author_username: org_support_bot.username } }

      subject(:items) { described_class.new(user, params).execute }

      it 'returns service desk issues for organization-specific support bot' do
        expect(items).to include(org_service_desk_issue)
      end
    end
  end

  # Regression test for https://gitlab.com/gitlab-org/gitlab/-/issues/589021
  # A Guest must not see confidential issues by combining assignee_id (to satisfy
  # includes_user? and bypass the confidentiality check) with assignee_username pointing
  # to a group that includes the victim (to expand results via OR semantics to their issues).
  describe 'confidential issue disclosure via assignee_id and group handle assignee_username' do
    let_it_be(:victim, freeze: false) { create(:user) }
    let_it_be(:attacker, freeze: false) { create(:user) }
    let_it_be(:project, freeze: false) { create(:project, :private) }
    # The attacker controls this group; the victim is a member so group handle expansion
    # would include the victim's issues if param mixing were allowed.
    let_it_be(:attacker_group, freeze: false) { create(:group, :private) }
    let_it_be(:confidential_issue, freeze: false) do
      create(:issue, :confidential, project: project, assignees: [victim])
    end

    before_all do
      project.add_owner(victim)
      project.add_guest(attacker)
      attacker_group.add_developer(attacker)
      attacker_group.add_guest(victim)
    end

    it 'does not expose confidential issues when combining assignee_id with a group handle' do
      params = {
        project_id: project.id,
        assignee_id: attacker.id,
        assignee_username: attacker_group.to_reference,
        scope: 'all'
      }
      items = described_class.new(attacker, params).execute

      expect(items).not_to include(confidential_issue)
    end
  end
end
