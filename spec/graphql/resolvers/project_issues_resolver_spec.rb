# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ProjectIssuesResolver, feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:reporter) { create(:user) }

  let_it_be(:group)         { create(:group) }
  let_it_be(:project)       { create(:project, group: group) }
  let_it_be(:other_project) { create(:project, group: group) }

  let_it_be(:started_milestone) { create(:milestone, project: project, title: "started milestone", start_date: 1.day.ago) }
  let_it_be(:assignee)  { create(:user) }
  let_it_be(:issue1)    { create(:incident, project: project, state: :opened, created_at: 3.hours.ago, updated_at: 3.hours.ago, milestone: started_milestone) }
  let_it_be(:issue2)    { create(:issue, project: project, state: :closed, title: 'foo', created_at: 1.hour.ago, updated_at: 1.hour.ago, closed_at: 1.hour.ago, assignees: [assignee]) }
  let_it_be(:issue3)    { create(:issue, project: other_project, state: :closed, title: 'foo', created_at: 1.hour.ago, updated_at: 1.hour.ago, closed_at: 1.hour.ago, assignees: [assignee]) }
  let_it_be(:issue4)    { create(:issue) }
  let_it_be(:label1)    { create(:label, project: project) }
  let_it_be(:label2)    { create(:label, project: project) }
  let_it_be(:upvote_award) { create(:award_emoji, :upvote, user: current_user, awardable: issue1) }

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::IssueType.connection_type)
  end

  context "with a project" do
    before_all do
      project.add_developer(current_user)
      project.add_reporter(reporter)

      create(:crm_settings, group: group, enabled: true)

      create(:label_link, label: label1, target: issue1)
      create(:label_link, label: label1, target: issue2)
      create(:label_link, label: label2, target: issue2)
    end

    describe '#resolve' do
      it 'finds all issues' do
        expect(resolve_issues).to contain_exactly(issue1, issue2)
      end

      it 'filters by state' do
        expect(resolve_issues(state: 'opened')).to contain_exactly(issue1)
        expect(resolve_issues(state: 'closed')).to contain_exactly(issue2)
      end

      it 'filters by milestone' do
        expect(resolve_issues(milestone_title: [started_milestone.title])).to contain_exactly(issue1)
      end

      describe 'filtering by milestone wildcard id' do
        let_it_be(:upcoming_milestone) { create(:milestone, project: project, title: "upcoming milestone", start_date: 1.day.ago, due_date: 1.day.from_now) }
        let_it_be(:past_milestone) { create(:milestone, project: project, title: "past milestone", due_date: 1.day.ago) }
        let_it_be(:future_milestone) { create(:milestone, project: project, title: "future milestone", start_date: 1.day.from_now) }
        let_it_be(:issue5) { create(:issue, project: project, state: :opened, milestone: upcoming_milestone) }
        let_it_be(:issue6) { create(:issue, project: project, state: :opened, milestone: past_milestone) }
        let_it_be(:issue7) { create(:issue, project: project, state: :opened, milestone: future_milestone) }

        let(:wildcard_started) { 'STARTED' }
        let(:wildcard_upcoming) { 'UPCOMING' }
        let(:wildcard_any) { 'ANY' }
        let(:wildcard_none) { 'NONE' }

        it 'returns issues with started milestone' do
          expect(resolve_issues(milestone_wildcard_id: wildcard_started)).to contain_exactly(issue1, issue5)
        end

        it 'returns issues with upcoming milestone' do
          expect(resolve_issues(milestone_wildcard_id: wildcard_upcoming)).to contain_exactly(issue5)
        end

        it 'returns issues with any milestone' do
          expect(resolve_issues(milestone_wildcard_id: wildcard_any)).to contain_exactly(issue1, issue5, issue6, issue7)
        end

        it 'returns issues with no milestone' do
          expect(resolve_issues(milestone_wildcard_id: wildcard_none)).to contain_exactly(issue2)
        end

        it 'generates a mutually exclusive filter error when wildcard and title are provided' do
          expect_graphql_error_to_be_created(GraphQL::Schema::Validator::ValidationFailedError, 'Only one of [milestoneTitle, milestoneWildcardId] arguments is allowed at the same time.') do
            resolve_issues(milestone_title: ["started milestone"], milestone_wildcard_id: wildcard_started)
          end
        end

        context 'when using negated filters' do
          it 'returns issues matching the searched title after applying a negated filter' do
            expect(resolve_issues(milestone_title: ['past milestone'], not: { milestone_wildcard_id: wildcard_upcoming })).to contain_exactly(issue6)
          end

          it 'returns issues excluding the ones with started milestone' do
            expect(resolve_issues(not: { milestone_wildcard_id: wildcard_started })).to contain_exactly(issue7)
          end

          it 'returns issues excluding the ones with upcoming milestone' do
            expect(resolve_issues(not: { milestone_wildcard_id: wildcard_upcoming })).to contain_exactly(issue6)
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
        let_it_be(:release_issue1) { create(:issue, project: project, milestone: milestone1) }
        let_it_be(:release_issue2) { create(:issue, project: project, milestone: milestone2) }
        let_it_be(:release_issue3) { create(:issue, project: project, milestone: milestone3) }

        describe 'filter by release_tag' do
          it 'returns all issues associated with the specified tags' do
            expect(resolve_issues(release_tag: [release1.tag, release3.tag])).to contain_exactly(release_issue1, release_issue3)
          end

          context 'when release_tag_wildcard_id is also provided' do
            it 'generates a mutually eclusive argument error' do
              expect_graphql_error_to_be_created(GraphQL::Schema::Validator::ValidationFailedError, 'Only one of [releaseTag, releaseTagWildcardId] arguments is allowed at the same time.') do
                resolve_issues(release_tag: [release1.tag], release_tag_wildcard_id: 'ANY')
              end
            end
          end
        end

        describe 'filter by negated release_tag' do
          it 'returns all issues not associated with the specified tags' do
            expect(resolve_issues(not: { release_tag: [release1.tag, release3.tag] })).to contain_exactly(release_issue2)
          end
        end

        describe 'filter by release_tag_wildcard_id' do
          subject { resolve_issues(release_tag_wildcard_id: wildcard_id) }

          context 'when filtering by ANY' do
            let(:wildcard_id) { 'ANY' }

            it { is_expected.to contain_exactly(release_issue1, release_issue2, release_issue3) }
          end

          context 'when filtering by NONE' do
            let(:wildcard_id) { 'NONE' }

            it { is_expected.to contain_exactly(issue1, issue2) }
          end
        end
      end

      it 'filters by two assignees' do
        assignee2 = create(:user)
        issue2.update!(assignees: [assignee, assignee2])

        expect(resolve_issues(assignee_id: [assignee.id, assignee2.id])).to contain_exactly(issue2)
      end

      it 'filters by assignee_id' do
        expect(resolve_issues(assignee_id: assignee.id)).to contain_exactly(issue2)
      end

      it 'filters by any assignee' do
        expect(resolve_issues(assignee_id: IssuableFinder::Params::FILTER_ANY)).to contain_exactly(issue2)
      end

      it 'filters by no assignee' do
        expect(resolve_issues(assignee_id: IssuableFinder::Params::FILTER_NONE)).to contain_exactly(issue1)
      end

      it 'filters by author' do
        expect(resolve_issues(author_username: issue1.author.username)).to contain_exactly(issue1, issue2)
      end

      it 'filters by labels' do
        expect(resolve_issues(label_name: [label1.title])).to contain_exactly(issue1, issue2)
        expect(resolve_issues(label_name: [label1.title, label2.title])).to contain_exactly(issue2)
      end

      describe 'filters by assignee_username' do
        it 'filters by assignee_username' do
          expect(resolve_issues(assignee_username: [assignee.username])).to contain_exactly(issue2)
        end

        it 'filters by assignee_usernames' do
          expect(resolve_issues(assignee_usernames: [assignee.username])).to contain_exactly(issue2)
        end

        context 'when both assignee_username and assignee_usernames are provided' do
          it 'generates a mutually exclusive filter error' do
            expect_graphql_error_to_be_created(GraphQL::Schema::Validator::ValidationFailedError, 'Only one of [assigneeUsernames, assigneeUsername, assigneeWildcardId] arguments is allowed at the same time.') do
              resolve_issues(assignee_usernames: [assignee.username], assignee_username: assignee.username)
            end
          end
        end
      end

      describe 'filters by created_at' do
        it 'filters by created_before' do
          expect(resolve_issues(created_before: 2.hours.ago)).to contain_exactly(issue1)
        end

        it 'filters by created_after' do
          expect(resolve_issues(created_after: 2.hours.ago)).to contain_exactly(issue2)
        end
      end

      describe 'filters by updated_at' do
        it 'filters by updated_before' do
          expect(resolve_issues(updated_before: 2.hours.ago)).to contain_exactly(issue1)
        end

        it 'filters by updated_after' do
          expect(resolve_issues(updated_after: 2.hours.ago)).to contain_exactly(issue2)
        end
      end

      describe 'filters by closed_at' do
        let!(:issue3) { create(:issue, project: project, state: :closed, closed_at: 3.hours.ago) }

        it 'filters by closed_before' do
          expect(resolve_issues(closed_before: 2.hours.ago)).to contain_exactly(issue3)
        end

        it 'filters by closed_after' do
          expect(resolve_issues(closed_after: 2.hours.ago)).to contain_exactly(issue2)
        end
      end

      describe 'filters by issue_type' do
        it 'filters by a single type' do
          expect(resolve_issues(types: %w[incident])).to contain_exactly(issue1)
        end

        it 'filters by a single type, negative assertion' do
          expect(resolve_issues(types: %w[issue])).not_to include(issue1)
        end

        it 'filters by more than one type' do
          expect(resolve_issues(types: %w[incident issue])).to contain_exactly(issue1, issue2)
        end

        it 'ignores the filter if none given' do
          expect(resolve_issues(types: [])).to contain_exactly(issue1, issue2)
        end
      end

      context 'when filtering by reaction emoji' do
        let_it_be(:downvoted_issue) { create(:issue, project: project) }
        let_it_be(:downvote_award) { create(:award_emoji, :downvote, user: current_user, awardable: downvoted_issue) }

        it 'filters by reaction emoji' do
          expect(resolve_issues(my_reaction_emoji: upvote_award.name)).to contain_exactly(issue1)
        end

        it 'filters by reaction emoji wildcard "none"' do
          expect(resolve_issues(my_reaction_emoji: 'none')).to contain_exactly(issue2)
        end

        it 'filters by reaction emoji wildcard "any"' do
          expect(resolve_issues(my_reaction_emoji: 'any')).to contain_exactly(issue1, downvoted_issue)
        end

        it 'filters by negated reaction emoji' do
          expect(resolve_issues(not: { my_reaction_emoji: downvote_award.name })).to contain_exactly(issue1, issue2)
        end
      end

      context 'when listing confidential issues' do
        let_it_be(:confidential_issue1) { create(:issue, project: project, confidential: true) }
        let_it_be(:confidential_issue2) { create(:issue, project: other_project, confidential: true) }

        context "when user is allowed to view confidential issues" do
          it 'returns all viewable issues by default' do
            expect(resolve_issues).to contain_exactly(issue1, issue2, confidential_issue1)
          end

          it 'returns only the non-confidential issues for the project when filter is set to false' do
            expect(resolve_issues({ confidential: false })).to contain_exactly(issue1, issue2)
          end

          it "returns only the confidential issues for the project when filter is set to true" do
            expect(resolve_issues({ confidential: true })).to contain_exactly(confidential_issue1)
          end
        end

        context "when user is not allowed to see confidential issues" do
          before do
            project.add_guest(current_user)
          end

          it 'returns all viewable issues by default' do
            expect(resolve_issues).to contain_exactly(issue1, issue2)
          end

          it 'does not return the confidential issues when filter is set to false' do
            expect(resolve_issues({ confidential: false })).to contain_exactly(issue1, issue2)
          end

          it 'does not return the confidential issues when filter is set to true' do
            expect(resolve_issues({ confidential: true })).to be_empty
          end
        end
      end

      context 'when searching issues' do
        it_behaves_like 'graphql query for searching issuables' do
          let_it_be(:parent) { project }
          let_it_be(:issuable1) { create(:issue, project: project, title: 'first created') }
          let_it_be(:issuable2) { create(:issue, project: project, title: 'second created', description: 'text 1') }
          let_it_be(:issuable3) { create(:issue, project: project, title: 'third', description: 'text 2') }
          let_it_be(:issuable4) { create(:issue, project: project) }

          let_it_be(:finder_class) { IssuesFinder }
          let_it_be(:optimization_param) { :attempt_project_search_optimizations }
        end
      end

      describe 'filters by negated params' do
        it 'returns issues without the specified iids' do
          expect(resolve_issues(not: { iids: [issue1.iid] })).to contain_exactly(issue2)
        end

        it 'returns issues without the specified label names' do
          expect(resolve_issues(not: { label_name: [label1.title] })).to be_empty
          expect(resolve_issues(not: { label_name: [label2.title] })).to contain_exactly(issue1)
        end

        it 'returns issues without the specified milestone' do
          expect(resolve_issues(not: { milestone_title: [started_milestone.title] })).to contain_exactly(issue2)
        end

        it 'returns issues without the specified assignee_usernames' do
          expect(resolve_issues(not: { assignee_usernames: [assignee.username] })).to contain_exactly(issue1)
        end

        it 'returns issues without the specified assignee_id' do
          expect(resolve_issues(not: { assignee_id: [assignee.id] })).to contain_exactly(issue1)
        end

        it 'returns issues without the specified issue_type' do
          expect(resolve_issues(not: { types: ['issue'] })).to contain_exactly(issue1)
        end

        context 'when filtering by negated author' do
          let_it_be(:issue_by_reporter) { create(:issue, author: reporter, project: project, state: :opened) }
          let_it_be(:other_user) { build_stubbed(:user) }

          it 'returns issues without the specified author_username' do
            expect(resolve_issues(not: { author_username: [issue1.author.username] })).to contain_exactly(issue_by_reporter)
          end

          it 'returns issues without the specified author_usernames' do
            expect(resolve_issues(not: { author_username: [issue1.author.username, other_user.username] })).to contain_exactly(issue_by_reporter)
          end
        end
      end

      describe 'filtering by crm' do
        let_it_be(:crm_organization) { create(:crm_organization, group: group) }
        let_it_be(:contact1) { create(:contact, group: group, organization: crm_organization) }
        let_it_be(:contact2) { create(:contact, group: group, organization: crm_organization) }
        let_it_be(:contact3) { create(:contact, group: group) }
        let_it_be(:crm_issue1) { create(:issue, project: project) }
        let_it_be(:crm_issue2) { create(:issue, project: project) }
        let_it_be(:crm_issue3) { create(:issue, project: project) }

        before_all do
          group.add_developer(current_user)

          create(:issue_customer_relations_contact, issue: crm_issue1, contact: contact1)
          create(:issue_customer_relations_contact, issue: crm_issue2, contact: contact2)
          create(:issue_customer_relations_contact, issue: crm_issue3, contact: contact3)
        end

        context 'when filtering by contact' do
          it 'returns only the issues for the contact' do
            expect(resolve_issues({ crm_contact_id: contact1.id })).to contain_exactly(crm_issue1)
          end
        end

        context 'when filtering by crm_organization' do
          it 'returns only the issues for the contact' do
            expect(resolve_issues({ crm_organization_id: crm_organization.id })).to contain_exactly(crm_issue1, crm_issue2)
          end
        end
      end

      # subscribed filtering handled in request spec, spec/requests/api/graphql/project/issues_spec.rb

      describe 'sorting' do
        context 'when sorting by created' do
          it 'sorts issues ascending' do
            expect(resolve_issues(sort: 'created_asc').to_a).to eq [issue1, issue2]
          end

          it 'sorts issues descending' do
            expect(resolve_issues(sort: 'created_desc').to_a).to eq [issue2, issue1]
          end
        end

        context 'when sorting by closed at' do
          let_it_be(:project) { create(:project, :public) }
          let_it_be(:closed_issue1) { create(:issue, project: project, closed_at: 3.days.from_now) }
          let_it_be(:closed_issue2) { create(:issue, project: project, closed_at: nil) }
          let_it_be(:closed_issue3) { create(:issue, project: project, closed_at: 2.days.ago) }
          let_it_be(:closed_issue4) { create(:issue, project: project, closed_at: nil) }

          it 'sorts issues ascending' do
            expect(resolve_issues(sort: :closed_at_asc).to_a).to eq [closed_issue3, closed_issue1, closed_issue4, closed_issue2]
          end

          it 'sorts issues descending' do
            expect(resolve_issues(sort: :closed_at_desc).to_a).to eq [closed_issue1, closed_issue3, closed_issue4, closed_issue2]
          end
        end

        context 'when sorting by due date' do
          let_it_be(:project) { create(:project, :public) }
          let_it_be(:due_issue1) { create(:issue, project: project, due_date: 3.days.from_now) }
          let_it_be(:due_issue2) { create(:issue, project: project, due_date: nil) }
          let_it_be(:due_issue3) { create(:issue, project: project, due_date: 2.days.ago) }
          let_it_be(:due_issue4) { create(:issue, project: project, due_date: nil) }

          it 'sorts issues ascending' do
            expect(resolve_issues(sort: :due_date_asc).to_a).to eq [due_issue3, due_issue1, due_issue4, due_issue2]
          end

          it 'sorts issues descending' do
            expect(resolve_issues(sort: :due_date_desc).to_a).to eq [due_issue1, due_issue3, due_issue4, due_issue2]
          end
        end

        context 'when sorting by relative position' do
          let_it_be(:project) { create(:project, :public) }
          let_it_be(:relative_issue1) { create(:issue, project: project, relative_position: 2000) }
          let_it_be(:relative_issue2) { create(:issue, project: project, relative_position: nil) }
          let_it_be(:relative_issue3) { create(:issue, project: project, relative_position: 1000) }
          let_it_be(:relative_issue4) { create(:issue, project: project, relative_position: nil) }

          it 'sorts issues ascending' do
            expect(resolve_issues(sort: :relative_position_asc).to_a).to eq [relative_issue3, relative_issue1, relative_issue2, relative_issue4]
          end
        end

        context 'when sorting by priority' do
          let_it_be(:project) { create(:project, :public) }
          let_it_be(:early_milestone) { create(:milestone, project: project, due_date: 10.days.from_now) }
          let_it_be(:late_milestone) { create(:milestone, project: project, due_date: 30.days.from_now) }
          let_it_be(:priority_label1) { create(:label, project: project, priority: 1) }
          let_it_be(:priority_label2) { create(:label, project: project, priority: 5) }
          let_it_be(:priority_issue1) { create(:issue, project: project, labels: [priority_label1], milestone: late_milestone) }
          let_it_be(:priority_issue2) { create(:issue, project: project, labels: [priority_label2]) }
          let_it_be(:priority_issue3) { create(:issue, project: project, milestone: early_milestone) }
          let_it_be(:priority_issue4) { create(:issue, project: project) }

          it 'sorts issues ascending' do
            expect(resolve_issues(sort: :priority_asc).to_a).to eq([priority_issue3, priority_issue1, priority_issue2, priority_issue4])
          end

          it 'sorts issues descending' do
            expect(resolve_issues(sort: :priority_desc).to_a).to eq([priority_issue1, priority_issue3, priority_issue2, priority_issue4])
          end
        end

        context 'when sorting by label priority' do
          let_it_be(:project) { create(:project, :public) }
          let_it_be(:label1) { create(:label, project: project, priority: 1) }
          let_it_be(:label2) { create(:label, project: project, priority: 5) }
          let_it_be(:label3) { create(:label, project: project, priority: 10) }
          let_it_be(:label_issue1) { create(:issue, project: project, labels: [label1]) }
          let_it_be(:label_issue2) { create(:issue, project: project, labels: [label2]) }
          let_it_be(:label_issue3) { create(:issue, project: project, labels: [label1, label3]) }
          let_it_be(:label_issue4) { create(:issue, project: project) }

          it 'sorts issues ascending' do
            expect(resolve_issues(sort: :label_priority_asc).to_a).to eq([label_issue3, label_issue1, label_issue2, label_issue4])
          end

          it 'sorts issues descending' do
            expect(resolve_issues(sort: :label_priority_desc).to_a).to eq([label_issue2, label_issue3, label_issue1, label_issue4])
          end
        end

        context 'when sorting by milestone due date' do
          let_it_be(:project) { create(:project, :public) }
          let_it_be(:early_milestone) { create(:milestone, project: project, due_date: 10.days.from_now) }
          let_it_be(:late_milestone) { create(:milestone, project: project, due_date: 30.days.from_now) }
          let_it_be(:milestone_issue1) { create(:issue, project: project) }
          let_it_be(:milestone_issue2) { create(:issue, project: project, milestone: early_milestone) }
          let_it_be(:milestone_issue3) { create(:issue, project: project, milestone: late_milestone) }

          it 'sorts issues ascending' do
            expect(resolve_issues(sort: :milestone_due_asc).to_a).to eq([milestone_issue2, milestone_issue3, milestone_issue1])
          end

          it 'sorts issues descending' do
            expect(resolve_issues(sort: :milestone_due_desc).to_a).to eq([milestone_issue3, milestone_issue2, milestone_issue1])
          end
        end

        context 'when sorting by severity' do
          let_it_be(:project) { create(:project, :public) }
          let_it_be(:issue_high_severity) { create_issue_with_severity(project, severity: :high) }
          let_it_be(:issue_low_severity) { create_issue_with_severity(project, severity: :low) }
          let_it_be(:issue_no_severity) { create(:incident, project: project) }

          it 'sorts issues ascending' do
            expect(resolve_issues(sort: :severity_asc).to_a).to eq([issue_no_severity, issue_low_severity, issue_high_severity])
          end

          it 'sorts issues descending' do
            expect(resolve_issues(sort: :severity_desc).to_a).to eq([issue_high_severity, issue_low_severity, issue_no_severity])
          end
        end

        context 'when sorting by popularity' do
          let_it_be(:project) { create(:project, :public) }
          let_it_be(:issue1) { create(:issue, project: project) } # has one upvote
          let_it_be(:issue2) { create(:issue, project: project) } # has two upvote
          let_it_be(:issue3) { create(:issue, project: project) }
          let_it_be(:issue4) { create(:issue, project: project) } # has one upvote

          before do
            create(:award_emoji, :upvote, awardable: issue1)
            create(:award_emoji, :upvote, awardable: issue2)
            create(:award_emoji, :upvote, awardable: issue2)
            create(:award_emoji, :upvote, awardable: issue4)
          end

          it 'sorts issues ascending (ties broken by id in desc order)' do
            expect(resolve_issues(sort: :popularity_asc).to_a).to eq([issue3, issue4, issue1, issue2])
          end

          it 'sorts issues descending (ties broken by id in desc order)' do
            expect(resolve_issues(sort: :popularity_desc).to_a).to eq([issue2, issue4, issue1, issue3])
          end
        end

        context 'when sorting by escalation status' do
          let_it_be(:project) { create(:project, :public) }
          let_it_be(:triggered_incident) { create(:incident, :with_escalation_status, project: project) }
          let_it_be(:issue_no_status) { create(:issue, project: project) }
          let_it_be(:resolved_incident) do
            create(:incident, :with_escalation_status, project: project)
              .tap { |issue| issue.escalation_status.resolve }
          end

          it 'sorts issues ascending' do
            issues = resolve_issues(sort: :escalation_status_asc).to_a
            expect(issues).to eq([triggered_incident, resolved_incident, issue_no_status])
          end

          it 'sorts issues descending' do
            issues = resolve_issues(sort: :escalation_status_desc).to_a
            expect(issues).to eq([resolved_incident, triggered_incident, issue_no_status])
          end

          it 'sorts issues created_at' do
            issues = resolve_issues(sort: :created_desc).to_a
            expect(issues).to eq([resolved_incident, issue_no_status, triggered_incident])
          end
        end

        context 'when sorting with non-stable cursors' do
          %i[priority_asc priority_desc
             popularity_asc popularity_desc
             label_priority_asc label_priority_desc
             milestone_due_asc milestone_due_desc
             escalation_status_asc escalation_status_desc].each do |sort_by|
            it "uses offset-pagination when sorting by #{sort_by}" do
              resolved = resolve_issues(sort: sort_by)

              expect(resolved).to be_a(::Gitlab::Graphql::Pagination::OffsetActiveRecordRelationConnection)
            end
          end
        end

        context 'when sorting by title' do
          let_it_be(:project) { create(:project, :public) }
          let_it_be(:issue1) { create(:issue, project: project, title: 'foo') }
          let_it_be(:issue2) { create(:issue, project: project, title: 'bar') }
          let_it_be(:issue3) { create(:issue, project: project, title: 'baz') }
          let_it_be(:issue4) { create(:issue, project: project, title: 'Baz 2') }

          it 'sorts issues ascending' do
            expect(resolve_issues(sort: :title_asc).to_a).to eq [issue2, issue3, issue4, issue1]
          end

          it 'sorts issues descending' do
            expect(resolve_issues(sort: :title_desc).to_a).to eq [issue1, issue4, issue3, issue2]
          end
        end
      end

      it 'returns issues user can see' do
        project.add_guest(current_user)

        create(:issue, confidential: true)

        expect(resolve_issues).to contain_exactly(issue1, issue2)
      end

      it 'finds a specific issue with iid', :request_store do
        result = batch_sync(max_queries: 11) { resolve_issues(iid: issue1.iid).to_a }

        expect(result).to contain_exactly(issue1)
      end

      it 'batches queries that only include IIDs', :request_store do
        result = batch_sync(max_queries: 11) do
          [issue1, issue2]
            .map { |issue| resolve_issues(iid: issue.iid.to_s) }
            .flat_map(&:to_a)
        end

        expect(result).to contain_exactly(issue1, issue2)
      end

      it 'finds a specific issue with iids', :request_store do
        result = batch_sync(max_queries: 11) do
          resolve_issues(iids: [issue1.iid]).to_a
        end

        expect(result).to contain_exactly(issue1)
      end

      it 'finds multiple issues with iids' do
        create(:issue, project: project, author: current_user)

        expect(batch_sync { resolve_issues(iids: [issue1.iid, issue2.iid]).to_a })
          .to contain_exactly(issue1, issue2)
      end

      it 'finds only the issues within the project we are looking at' do
        another_project = create(:project)
        iids = [issue1, issue2].map(&:iid)

        iids.each do |iid|
          create(:issue, project: another_project, iid: iid)
        end

        expect(batch_sync { resolve_issues(iids: iids).to_a }).to contain_exactly(issue1, issue2)
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
      expect(resolve_issues(iids: ["don't", "break"])).to be_empty
    end
  end

  it 'increases field complexity based on arguments' do
    field = Types::BaseField.new(name: 'test', type: GraphQL::Types::String.connection_type, resolver_class: described_class, null: false, max_page_size: 100)

    expect(field.complexity.call({}, {}, 1)).to eq 4
    expect(field.complexity.call({}, { labelName: 'foo' }, 1)).to eq 8
  end

  def create_issue_with_severity(project, severity:)
    issue = create(:incident, project: project)
    create(:issuable_severity, issue: issue, severity: severity)

    issue
  end

  def resolve_issues(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: project, args: args, ctx: context, arg_style: :internal)
  end
end
