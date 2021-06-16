# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuesFinder do
  using RSpec::Parameterized::TableSyntax
  include_context 'IssuesFinder context'

  describe '#execute' do
    include_context 'IssuesFinder#execute context'

    context 'scope: all' do
      let(:scope) { 'all' }

      it 'returns all issues' do
        expect(issues).to contain_exactly(issue1, issue2, issue3, issue4, issue5)
      end

      context 'user does not have read permissions' do
        let(:search_user) { user2 }

        context 'when filtering by project id' do
          let(:params) { { project_id: project1.id } }

          it 'returns no issues' do
            expect(issues).to be_empty
          end
        end

        context 'when filtering by group id' do
          let(:params) { { group_id: group.id } }

          it 'returns no issues' do
            expect(issues).to be_empty
          end
        end
      end

      context 'assignee filtering' do
        let(:issuables) { issues }

        it_behaves_like 'assignee ID filter' do
          let(:params) { { assignee_id: user.id } }
          let(:expected_issuables) { [issue1, issue2, issue5] }
        end

        it_behaves_like 'assignee NOT ID filter' do
          let(:params) { { not: { assignee_id: user.id } } }
          let(:expected_issuables) { [issue3, issue4] }
        end

        it_behaves_like 'assignee OR filter' do
          let(:params) { { or: { assignee_id: [user.id, user2.id] } } }
          let(:expected_issuables) { [issue1, issue2, issue3, issue5] }
        end

        context 'when assignee_id does not exist' do
          it_behaves_like 'assignee NOT ID filter' do
            let(:params) { { not: { assignee_id: -100 } } }
            let(:expected_issuables) { [issue1, issue2, issue3, issue4, issue5] }
          end
        end

        context 'filter by username' do
          let_it_be(:user3) { create(:user) }

          before do
            project2.add_developer(user3)
            issue2.assignees = [user2]
            issue3.assignees = [user3]
          end

          it_behaves_like 'assignee username filter' do
            let(:params) { { assignee_username: [user2.username] } }
            let(:expected_issuables) { [issue2] }
          end

          it_behaves_like 'assignee NOT username filter' do
            before do
              issue2.assignees = [user2]
            end

            let(:params) { { not: { assignee_username: [user.username, user2.username] } } }
            let(:expected_issuables) { [issue3, issue4] }
          end

          it_behaves_like 'assignee OR filter' do
            let(:params) { { or: { assignee_username: [user2.username, user3.username] } } }
            let(:expected_issuables) { [issue2, issue3] }
          end

          context 'when assignee_username does not exist' do
            it_behaves_like 'assignee NOT username filter' do
              before do
                issue2.assignees = [user2]
              end

              let(:params) { { not: { assignee_username: 'non_existent_username' } } }
              let(:expected_issuables) { [issue1, issue2, issue3, issue4, issue5] }
            end
          end
        end

        it_behaves_like 'no assignee filter' do
          let_it_be(:user3) { create(:user) }
          let(:expected_issuables) { [issue4] }
        end

        it_behaves_like 'any assignee filter' do
          let(:expected_issuables) { [issue1, issue2, issue3, issue5] }
        end
      end

      context 'filtering by release' do
        context 'when the release tag is none' do
          let(:params) { { release_tag: 'none' } }

          it 'returns issues without releases' do
            expect(issues).to contain_exactly(issue2, issue3, issue4, issue5)
          end
        end

        context 'when the release tag exists' do
          let(:params) { { project_id: project1.id, release_tag: release.tag } }

          it 'returns the issues associated with that release' do
            expect(issues).to contain_exactly(issue1)
          end
        end
      end

      context 'filtering by projects' do
        context 'when projects are passed in a list of ids' do
          let(:params) { { projects: [project1.id] } }

          it 'returns the issue belonging to the projects' do
            expect(issues).to contain_exactly(issue1, issue5)
          end
        end

        context 'when projects are passed in a subquery' do
          let(:params) { { projects: Project.id_in(project1.id) } }

          it 'returns the issue belonging to the projects' do
            expect(issues).to contain_exactly(issue1, issue5)
          end
        end
      end

      context 'filtering by group_id' do
        let(:params) { { group_id: group.id } }

        context 'when include_subgroup param not set' do
          it 'returns all group issues' do
            expect(issues).to contain_exactly(issue1, issue5)
          end

          context 'when projects outside the group are passed' do
            let(:params) { { group_id: group.id, projects: [project2.id] } }

            it 'returns no issues' do
              expect(issues).to be_empty
            end
          end

          context 'when projects of the group are passed' do
            let(:params) { { group_id: group.id, projects: [project1.id] } }

            it 'returns the issue within the group and projects' do
              expect(issues).to contain_exactly(issue1, issue5)
            end
          end

          context 'when projects of the group are passed as a subquery' do
            let(:params) { { group_id: group.id, projects: Project.id_in(project1.id) } }

            it 'returns the issue within the group and projects' do
              expect(issues).to contain_exactly(issue1, issue5)
            end
          end

          context 'when release_tag is passed as a parameter' do
            let(:params) { { group_id: group.id, release_tag: 'dne-release-tag' } }

            it 'ignores the release_tag parameter' do
              expect(issues).to contain_exactly(issue1, issue5)
            end
          end
        end

        context 'when include_subgroup param is true' do
          before do
            params[:include_subgroups] = true
          end

          it 'returns all group and subgroup issues' do
            expect(issues).to contain_exactly(issue1, issue4, issue5)
          end

          context 'when mixed projects are passed' do
            let(:params) { { group_id: group.id, projects: [project2.id, project3.id] } }

            it 'returns the issue within the group and projects' do
              expect(issues).to contain_exactly(issue4)
            end
          end
        end
      end

      context 'filtering by author' do
        context 'by author ID' do
          let(:params) { { author_id: user2.id } }

          it 'returns issues created by that user' do
            expect(issues).to contain_exactly(issue3)
          end
        end

        context 'using OR' do
          let(:issue6) { create(:issue, project: project2) }
          let(:params) { { or: { author_username: [issue3.author.username, issue6.author.username] } } }

          it 'returns issues created by any of the given users' do
            expect(issues).to contain_exactly(issue3, issue6)
          end

          context 'when feature flag is disabled' do
            before do
              stub_feature_flags(or_issuable_queries: false)
            end

            it 'does not add any filter' do
              expect(issues).to contain_exactly(issue1, issue2, issue3, issue4, issue5, issue6)
            end
          end
        end

        context 'filtering by NOT author ID' do
          let(:params) { { not: { author_id: user2.id } } }

          it 'returns issues not created by that user' do
            expect(issues).to contain_exactly(issue1, issue2, issue4, issue5)
          end
        end

        context 'filtering by nonexistent author ID and issue term using CTE for search' do
          let(:params) do
            {
              author_id: 'does-not-exist',
              search: 'git',
              attempt_group_search_optimizations: true
            }
          end

          it 'returns no results' do
            expect(issues).to be_empty
          end
        end
      end

      context 'filtering by milestone' do
        let(:params) { { milestone_title: milestone.title } }

        it 'returns issues assigned to that milestone' do
          expect(issues).to contain_exactly(issue1)
        end
      end

      context 'filtering by not milestone' do
        let(:params) { { not: { milestone_title: milestone.title } } }

        it 'returns issues not assigned to that milestone' do
          expect(issues).to contain_exactly(issue2, issue3, issue4, issue5)
        end
      end

      context 'filtering by group milestone' do
        let!(:group) { create(:group, :public) }
        let(:group_milestone) { create(:milestone, group: group) }
        let!(:group_member) { create(:group_member, group: group, user: user) }
        let(:params) { { milestone_title: group_milestone.title } }

        before do
          project2.update!(namespace: group)
          issue2.update!(milestone: group_milestone)
          issue3.update!(milestone: group_milestone)
        end

        it 'returns issues assigned to that group milestone' do
          expect(issues).to contain_exactly(issue2, issue3)
        end

        context 'using NOT' do
          let(:params) { { not: { milestone_title: group_milestone.title } } }

          it 'returns issues not assigned to that group milestone' do
            expect(issues).to contain_exactly(issue1, issue4, issue5)
          end
        end
      end

      context 'filtering by no milestone' do
        let(:params) { { milestone_title: 'None' } }

        it 'returns issues with no milestone' do
          expect(issues).to contain_exactly(issue2, issue3, issue4, issue5)
        end

        it 'returns issues with no milestone (deprecated)' do
          params[:milestone_title] = Milestone::None.title

          expect(issues).to contain_exactly(issue2, issue3, issue4, issue5)
        end
      end

      context 'filtering by any milestone' do
        let(:params) { { milestone_title: 'Any' } }

        it 'returns issues with any assigned milestone' do
          expect(issues).to contain_exactly(issue1)
        end

        it 'returns issues with any assigned milestone (deprecated)' do
          params[:milestone_title] = Milestone::Any.title

          expect(issues).to contain_exactly(issue1)
        end
      end

      context 'filtering by upcoming milestone' do
        let(:params) { { milestone_title: Milestone::Upcoming.name } }

        let!(:group) { create(:group, :public) }
        let!(:group_member) { create(:group_member, group: group, user: user) }

        let(:project_no_upcoming_milestones) { create(:project, :public) }
        let(:project_next_1_1) { create(:project, :public) }
        let(:project_next_8_8) { create(:project, :public) }
        let(:project_in_group) { create(:project, :public, namespace: group) }

        let(:yesterday) { Date.current - 1.day }
        let(:tomorrow) { Date.current + 1.day }
        let(:two_days_from_now) { Date.current + 2.days }
        let(:ten_days_from_now) { Date.current + 10.days }

        let(:milestones) do
          [
            create(:milestone, :closed, project: project_no_upcoming_milestones),
            create(:milestone, project: project_next_1_1, title: '1.1', due_date: two_days_from_now),
            create(:milestone, project: project_next_1_1, title: '8.9', due_date: ten_days_from_now),
            create(:milestone, project: project_next_8_8, title: '1.2', due_date: yesterday),
            create(:milestone, project: project_next_8_8, title: '8.8', due_date: tomorrow),
            create(:milestone, group: group, title: '9.9', due_date: tomorrow)
          ]
        end

        before do
          @created_issues = milestones.map do |milestone|
            create(:issue, project: milestone.project || project_in_group, milestone: milestone, author: user, assignees: [user])
          end
        end

        it 'returns issues in the upcoming milestone for each project or group' do
          expect(issues.map { |issue| issue.milestone.title }).to contain_exactly('1.1', '8.8', '9.9')
          expect(issues.map { |issue| issue.milestone.due_date }).to contain_exactly(tomorrow, two_days_from_now, tomorrow)
        end

        context 'using NOT' do
          let(:params) { { not: { milestone_title: Milestone::Upcoming.name } } }

          it 'returns issues not in upcoming milestones for each project or group, but must have a due date' do
            target_issues = @created_issues.select do |issue|
              issue.milestone&.due_date && issue.milestone.due_date <= Date.current
            end

            expect(issues).to contain_exactly(*target_issues)
          end
        end
      end

      context 'filtering by started milestone' do
        let(:params) { { milestone_title: Milestone::Started.name } }

        let(:project_no_started_milestones) { create(:project, :public) }
        let(:project_started_1_and_2) { create(:project, :public) }
        let(:project_started_8) { create(:project, :public) }

        let(:yesterday) { Date.current - 1.day }
        let(:tomorrow) { Date.current + 1.day }
        let(:two_days_ago) { Date.current - 2.days }
        let(:three_days_ago) { Date.current - 3.days }

        let(:milestones) do
          [
            create(:milestone, project: project_no_started_milestones, start_date: tomorrow),
            create(:milestone, project: project_started_1_and_2, title: '1.0', start_date: two_days_ago),
            create(:milestone, project: project_started_1_and_2, title: '2.0', start_date: yesterday),
            create(:milestone, project: project_started_1_and_2, title: '3.0', start_date: tomorrow),
            create(:milestone, :closed, project: project_started_1_and_2, title: '4.0', start_date: three_days_ago),
            create(:milestone, :closed, project: project_started_8, title: '6.0', start_date: three_days_ago),
            create(:milestone, project: project_started_8, title: '7.0'),
            create(:milestone, project: project_started_8, title: '8.0', start_date: yesterday),
            create(:milestone, project: project_started_8, title: '9.0', start_date: tomorrow)
          ]
        end

        before do
          milestones.each do |milestone|
            create(:issue, project: milestone.project, milestone: milestone, author: user, assignees: [user])
          end
        end

        it 'returns issues in the started milestones for each project' do
          expect(issues.map { |issue| issue.milestone.title }).to contain_exactly('1.0', '2.0', '8.0')
          expect(issues.map { |issue| issue.milestone.start_date }).to contain_exactly(two_days_ago, yesterday, yesterday)
        end

        context 'using NOT' do
          let(:params) { { not: { milestone_title: Milestone::Started.name } } }

          it 'returns issues not in the started milestones for each project' do
            target_issues = Issue.where(milestone: Milestone.not_started)

            expect(issues).to contain_exactly(*target_issues)
          end
        end
      end

      shared_examples ':label_name parameter' do
        context 'filtering by label' do
          let(:params) { { label_name: label.title } }

          it 'returns issues with that label' do
            expect(issues).to contain_exactly(issue2)
          end

          context 'using NOT' do
            let(:params) { { not: { label_name: label.title } } }

            it 'returns issues that do not have that label' do
              expect(issues).to contain_exactly(issue1, issue3, issue4, issue5)
            end

            # IssuableFinder first filters using the outer params (the ones not inside the `not` key.)
            # Afterwards, it applies the `not` params to that resultset. This means that things inside the `not` param
            # do not take precedence over the outer params with the same name.
            context 'shadowing the same outside param' do
              let(:params) { { label_name: label2.title, not: { label_name: label.title } } }

              it 'does not take precedence over labels outside NOT' do
                expect(issues).to contain_exactly(issue3)
              end
            end

            context 'further filtering outside params' do
              let(:params) { { label_name: label2.title, not: { assignee_username: user2.username } } }

              it 'further filters on the returned resultset' do
                expect(issues).to be_empty
              end
            end
          end
        end

        context 'filtering by multiple labels' do
          let(:params) { { label_name: [label.title, label2.title].join(',') } }
          let(:label2) { create(:label, project: project2) }

          before do
            create(:label_link, label: label2, target: issue2)
          end

          it 'returns the unique issues with all those labels' do
            expect(issues).to contain_exactly(issue2)
          end

          context 'using NOT' do
            let(:params) { { not: { label_name: [label.title, label2.title].join(',') } } }

            it 'returns issues that do not have any of the labels provided' do
              expect(issues).to contain_exactly(issue1, issue4, issue5)
            end
          end
        end

        context 'filtering by a label that includes any or none in the title' do
          let(:params) { { label_name: [label.title, label2.title].join(',') } }
          let(:label) { create(:label, title: 'any foo', project: project2) }
          let(:label2) { create(:label, title: 'bar none', project: project2) }

          before do
            create(:label_link, label: label2, target: issue2)
          end

          it 'returns the unique issues with all those labels' do
            expect(issues).to contain_exactly(issue2)
          end

          context 'using NOT' do
            let(:params) { { not: { label_name: [label.title, label2.title].join(',') } } }

            it 'returns issues that do not have ANY ONE of the labels provided' do
              expect(issues).to contain_exactly(issue1, issue4, issue5)
            end
          end
        end

        context 'filtering by no label' do
          let(:params) { { label_name: described_class::Params::FILTER_NONE } }

          it 'returns issues with no labels' do
            expect(issues).to contain_exactly(issue1, issue4, issue5)
          end
        end

        context 'filtering by any label' do
          let(:params) { { label_name: described_class::Params::FILTER_ANY } }

          it 'returns issues that have one or more label' do
            create_list(:label_link, 2, label: create(:label, project: project2), target: issue3)

            expect(issues).to contain_exactly(issue2, issue3)
          end
        end

        context 'when the same label exists on project and group levels' do
          let(:issue1) { create(:issue, project: project1) }
          let(:issue2) { create(:issue, project: project1) }

          # Skipping validation to reproduce a "real-word" scenario.
          # We still have legacy labels on PRD that have the same title on the group and project levels, example: `bug`
          let(:project_label) { build(:label, title: 'somelabel', project: project1).tap { |r| r.save!(validate: false) } }
          let(:group_label) { create(:group_label, title: 'somelabel', group: project1.group) }

          let(:params) { { label_name: 'somelabel' } }

          before do
            create(:label_link, label: group_label, target: issue1)
            create(:label_link, label: project_label, target: issue2)
          end

          it 'finds both issue records' do
            expect(issues).to contain_exactly(issue1, issue2)
          end
        end
      end

      context 'when `optimized_issuable_label_filter` feature flag is off' do
        before do
          stub_feature_flags(optimized_issuable_label_filter: false)
        end

        it_behaves_like ':label_name parameter'
      end

      context 'when `optimized_issuable_label_filter` feature flag is on' do
        before do
          stub_feature_flags(optimized_issuable_label_filter: true)
        end

        it_behaves_like ':label_name parameter'
      end

      context 'filtering by issue term' do
        let(:params) { { search: 'git' } }

        it 'returns issues with title and description match for search term' do
          expect(issues).to contain_exactly(issue1, issue2)
        end
      end

      context 'filtering by issue term in title' do
        let(:params) { { search: 'git', in: 'title' } }

        it 'returns issues with title match for search term' do
          expect(issues).to contain_exactly(issue1)
        end
      end

      context 'filtering by issues iids' do
        let(:params) { { iids: [issue3.iid] } }

        it 'returns issues where iids match' do
          expect(issues).to contain_exactly(issue3, issue5)
        end

        context 'using NOT' do
          let(:params) { { not: { iids: [issue3.iid] } } }

          it 'returns issues with no iids match' do
            expect(issues).to contain_exactly(issue1, issue2, issue4)
          end
        end
      end

      context 'filtering by state' do
        context 'with opened' do
          let(:params) { { state: 'opened' } }

          it 'returns only opened issues' do
            expect(issues).to contain_exactly(issue1, issue2, issue3, issue4, issue5)
          end
        end

        context 'with closed' do
          let(:params) { { state: 'closed' } }

          it 'returns only closed issues' do
            expect(issues).to contain_exactly(closed_issue)
          end
        end

        context 'with all' do
          let(:params) { { state: 'all' } }

          it 'returns all issues' do
            expect(issues).to contain_exactly(issue1, issue2, issue3, closed_issue, issue4, issue5)
          end
        end

        context 'with invalid state' do
          let(:params) { { state: 'invalid_state' } }

          it 'returns all issues' do
            expect(issues).to contain_exactly(issue1, issue2, issue3, closed_issue, issue4, issue5)
          end
        end
      end

      context 'filtering by created_at' do
        context 'through created_after' do
          let(:params) { { created_after: issue3.created_at } }

          it 'returns issues created on or after the given date' do
            expect(issues).to contain_exactly(issue3)
          end
        end

        context 'through created_before' do
          let(:params) { { created_before: issue1.created_at } }

          it 'returns issues created on or before the given date' do
            expect(issues).to contain_exactly(issue1)
          end
        end

        context 'through created_after and created_before' do
          let(:params) { { created_after: issue2.created_at, created_before: issue3.created_at } }

          it 'returns issues created between the given dates' do
            expect(issues).to contain_exactly(issue2, issue3)
          end
        end
      end

      context 'filtering by updated_at' do
        context 'through updated_after' do
          let(:params) { { updated_after: issue3.updated_at } }

          it 'returns issues updated on or after the given date' do
            expect(issues).to contain_exactly(issue3)
          end
        end

        context 'through updated_before' do
          let(:params) { { updated_before: issue1.updated_at } }

          it 'returns issues updated on or before the given date' do
            expect(issues).to contain_exactly(issue1)
          end
        end

        context 'through updated_after and updated_before' do
          let(:params) { { updated_after: issue2.updated_at, updated_before: issue3.updated_at } }

          it 'returns issues updated between the given dates' do
            expect(issues).to contain_exactly(issue2, issue3)
          end
        end
      end

      context 'filtering by closed_at' do
        let!(:closed_issue1) { create(:issue, project: project1, state: :closed, closed_at: 1.week.ago) }
        let!(:closed_issue2) { create(:issue, project: project2, state: :closed, closed_at: 1.week.from_now) }
        let!(:closed_issue3) { create(:issue, project: project2, state: :closed, closed_at: 2.weeks.from_now) }

        context 'through closed_after' do
          let(:params) { { state: :closed, closed_after: closed_issue3.closed_at } }

          it 'returns issues closed on or after the given date' do
            expect(issues).to contain_exactly(closed_issue3)
          end
        end

        context 'through closed_before' do
          let(:params) { { state: :closed, closed_before: closed_issue1.closed_at } }

          it 'returns issues closed on or before the given date' do
            expect(issues).to contain_exactly(closed_issue1)
          end
        end

        context 'through closed_after and closed_before' do
          let(:params) { { state: :closed, closed_after: closed_issue2.closed_at, closed_before: closed_issue3.closed_at } }

          it 'returns issues closed between the given dates' do
            expect(issues).to contain_exactly(closed_issue2, closed_issue3)
          end
        end
      end

      context 'filtering by reaction name' do
        context 'user searches by no reaction' do
          let(:params) { { my_reaction_emoji: 'None' } }

          it 'returns issues that the user did not react to' do
            expect(issues).to contain_exactly(issue2, issue4, issue5)
          end
        end

        context 'user searches by any reaction' do
          let(:params) { { my_reaction_emoji: 'Any' } }

          it 'returns issues that the user reacted to' do
            expect(issues).to contain_exactly(issue1, issue3)
          end
        end

        context 'user searches by "thumbsup" reaction' do
          let(:params) { { my_reaction_emoji: 'thumbsup' } }

          it 'returns issues that the user thumbsup to' do
            expect(issues).to contain_exactly(issue1)
          end

          context 'using NOT' do
            let(:params) { { not: { my_reaction_emoji: 'thumbsup' } } }

            it 'returns issues that the user did not thumbsup to' do
              expect(issues).to contain_exactly(issue2, issue3, issue4, issue5)
            end
          end
        end

        context 'user2 searches by "thumbsup" reaction' do
          let(:search_user) { user2 }

          let(:params) { { my_reaction_emoji: 'thumbsup' } }

          it 'returns issues that the user2 thumbsup to' do
            expect(issues).to contain_exactly(issue2)
          end

          context 'using NOT' do
            let(:params) { { not: { my_reaction_emoji: 'thumbsup' } } }

            it 'returns issues that the user2 thumbsup to' do
              expect(issues).to contain_exactly(issue3)
            end
          end
        end

        context 'user searches by "thumbsdown" reaction' do
          let(:params) { { my_reaction_emoji: 'thumbsdown' } }

          it 'returns issues that the user thumbsdown to' do
            expect(issues).to contain_exactly(issue3)
          end

          context 'using NOT' do
            let(:params) { { not: { my_reaction_emoji: 'thumbsdown' } } }

            it 'returns issues that the user thumbsdown to' do
              expect(issues).to contain_exactly(issue1, issue2, issue4, issue5)
            end
          end
        end
      end

      context 'filtering by confidential' do
        let_it_be(:confidential_issue) { create(:issue, project: project1, confidential: true) }

        context 'no filtering' do
          it 'returns all issues' do
            expect(issues).to contain_exactly(issue1, issue2, issue3, issue4, issue5, confidential_issue)
          end
        end

        context 'user filters confidential issues' do
          let(:params) { { confidential: true } }

          it 'returns only confdential issues' do
            expect(issues).to contain_exactly(confidential_issue)
          end
        end

        context 'user filters only public issues' do
          let(:params) { { confidential: false } }

          it 'returns only confdential issues' do
            expect(issues).to contain_exactly(issue1, issue2, issue3, issue4, issue5)
          end
        end
      end

      context 'filtering by issue type' do
        let_it_be(:incident_issue) { create(:incident, project: project1) }

        context 'no type given' do
          let(:params) { { issue_types: [] } }

          it 'returns all issues' do
            expect(issues).to contain_exactly(incident_issue, issue1, issue2, issue3, issue4, issue5)
          end
        end

        context 'incident type' do
          let(:params) { { issue_types: ['incident'] } }

          it 'returns incident issues' do
            expect(issues).to contain_exactly(incident_issue)
          end
        end

        context 'issue type' do
          let(:params) { { issue_types: ['issue'] } }

          it 'returns all issues with type issue' do
            expect(issues).to contain_exactly(issue1, issue2, issue3, issue4, issue5)
          end
        end

        context 'multiple params' do
          let(:params) { { issue_types: %w(issue incident) } }

          it 'returns all issues' do
            expect(issues).to contain_exactly(incident_issue, issue1, issue2, issue3, issue4, issue5)
          end
        end

        context 'without array' do
          let(:params) { { issue_types: 'incident' } }

          it 'returns incident issues' do
            expect(issues).to contain_exactly(incident_issue)
          end
        end

        context 'invalid params' do
          let(:params) { { issue_types: ['nonsense'] } }

          it 'returns no issues' do
            expect(issues).to eq(Issue.none)
          end
        end
      end

      context 'when the user is unauthorized' do
        let(:search_user) { nil }

        it 'returns no results' do
          expect(issues).to be_empty
        end
      end

      context 'when the user can see some, but not all, issues' do
        let(:search_user) { user2 }

        it 'returns only issues they can see' do
          expect(issues).to contain_exactly(issue2, issue3)
        end
      end

      it 'finds issues user can access due to group' do
        group = create(:group)
        project = create(:project, group: group)
        issue = create(:issue, project: project)
        group.add_user(user, :owner)

        expect(issues).to include(issue)
      end
    end

    context 'personal scope' do
      let(:scope) { 'assigned_to_me' }

      it 'returns issue assigned to the user' do
        expect(issues).to contain_exactly(issue1, issue2, issue5)
      end

      context 'filtering by project' do
        let(:params) { { project_id: project1.id } }

        it 'returns issues assigned to the user in that project' do
          expect(issues).to contain_exactly(issue1, issue5)
        end
      end
    end

    context 'when project restricts issues' do
      let(:scope) { nil }

      it "doesn't return team-only issues to non team members" do
        project = create(:project, :public, :issues_private)
        issue = create(:issue, project: project)

        expect(issues).not_to include(issue)
      end

      it "doesn't return issues if feature disabled" do
        [project1, project2, project3].each do |project|
          project.project_feature.update!(issues_access_level: ProjectFeature::DISABLED)
        end

        expect(issues.count).to eq 0
      end
    end

    context 'external authorization' do
      it_behaves_like 'a finder with external authorization service' do
        let!(:subject) { create(:issue, project: project) }
        let(:project_params) { { project_id: project.id } }
      end
    end

    context 'filtering by due date' do
      let_it_be(:issue_overdue) { create(:issue, project: project1, due_date: 2.days.ago) }
      let_it_be(:issue_due_soon) { create(:issue, project: project1, due_date: 2.days.from_now) }

      let(:scope) { 'all' }
      let(:base_params) { { project_id: project1.id } }

      context 'with param set to no due date' do
        let(:params) { base_params.merge(due_date: Issue::NoDueDate.name) }

        it 'returns issues with no due date' do
          expect(issues).to contain_exactly(issue1, issue5)
        end
      end

      context 'with param set to overdue' do
        let(:params) { base_params.merge(due_date: Issue::Overdue.name) }

        it 'returns overdue issues' do
          expect(issues).to contain_exactly(issue_overdue)
        end
      end

      context 'with param set to next month and previous two weeks' do
        let(:params) { base_params.merge(due_date: Issue::DueNextMonthAndPreviousTwoWeeks.name) }

        it 'returns issues from the previous two weeks and next month' do
          expect(issues).to contain_exactly(issue_overdue, issue_due_soon)
        end
      end

      context 'with invalid param' do
        let(:params) { base_params.merge(due_date: 'foo') }

        it 'returns no issues' do
          expect(issues).to be_empty
        end
      end
    end
  end

  describe '#row_count', :request_store do
    let_it_be(:admin) { create(:admin) }

    context 'when admin mode is enabled', :enable_admin_mode do
      it 'returns the number of rows for the default state' do
        finder = described_class.new(admin)

        expect(finder.row_count).to eq(5)
      end

      it 'returns the number of rows for a given state' do
        finder = described_class.new(admin, state: 'closed')

        expect(finder.row_count).to be_zero
      end
    end

    context 'when admin mode is disabled' do
      it 'returns no rows' do
        finder = described_class.new(admin)

        expect(finder.row_count).to be_zero
      end
    end

    it 'returns -1 if the query times out' do
      finder = described_class.new(admin)

      expect_next_instance_of(described_class) do |subfinder|
        expect(subfinder).to receive(:execute).and_raise(ActiveRecord::QueryCanceled)
      end

      expect(finder.row_count).to eq(-1)
    end
  end

  describe '#with_confidentiality_access_check' do
    let(:guest) { create(:user) }

    let_it_be(:authorized_user) { create(:user) }
    let_it_be(:project) { create(:project, namespace: authorized_user.namespace) }
    let_it_be(:public_issue) { create(:issue, project: project) }
    let_it_be(:confidential_issue) { create(:issue, project: project, confidential: true) }

    context 'when no project filter is given' do
      let(:params) { {} }

      context 'for an anonymous user' do
        subject { described_class.new(nil, params).with_confidentiality_access_check }

        it 'returns only public issues' do
          expect(subject).to include(public_issue)
          expect(subject).not_to include(confidential_issue)
        end
      end

      context 'for a user without project membership' do
        subject { described_class.new(user, params).with_confidentiality_access_check }

        it 'returns only public issues' do
          expect(subject).to include(public_issue)
          expect(subject).not_to include(confidential_issue)
        end
      end

      context 'for a guest user' do
        subject { described_class.new(guest, params).with_confidentiality_access_check }

        before do
          project.add_guest(guest)
        end

        it 'returns only public issues' do
          expect(subject).to include(public_issue)
          expect(subject).not_to include(confidential_issue)
        end
      end

      context 'for a project member with access to view confidential issues' do
        subject { described_class.new(authorized_user, params).with_confidentiality_access_check }

        it 'returns all issues' do
          expect(subject).to include(public_issue, confidential_issue)
        end
      end

      context 'for an admin' do
        let(:admin_user) { create(:user, :admin) }

        subject { described_class.new(admin_user, params).with_confidentiality_access_check }

        context 'when admin mode is enabled', :enable_admin_mode do
          it 'returns all issues' do
            expect(subject).to include(public_issue, confidential_issue)
          end
        end

        context 'when admin mode is disabled' do
          it 'returns only public issues' do
            expect(subject).to include(public_issue)
            expect(subject).not_to include(confidential_issue)
          end
        end
      end
    end

    context 'when searching within a specific project' do
      let(:params) { { project_id: project.id } }

      context 'for an anonymous user' do
        subject { described_class.new(nil, params).with_confidentiality_access_check }

        it 'returns only public issues' do
          expect(subject).to include(public_issue)
          expect(subject).not_to include(confidential_issue)
        end

        it 'does not filter by confidentiality' do
          expect(Issue).not_to receive(:where).with(a_string_matching('confidential'), anything)

          subject
        end
      end

      context 'for a user without project membership' do
        subject { described_class.new(user, params).with_confidentiality_access_check }

        it 'returns only public issues' do
          expect(subject).to include(public_issue)
          expect(subject).not_to include(confidential_issue)
        end

        it 'filters by confidentiality' do
          expect(subject.to_sql).to match("issues.confidential")
        end
      end

      context 'for a guest user' do
        subject { described_class.new(guest, params).with_confidentiality_access_check }

        before do
          project.add_guest(guest)
        end

        it 'returns only public issues' do
          expect(subject).to include(public_issue)
          expect(subject).not_to include(confidential_issue)
        end

        it 'filters by confidentiality' do
          expect(subject.to_sql).to match("issues.confidential")
        end
      end

      context 'for a project member with access to view confidential issues' do
        subject { described_class.new(authorized_user, params).with_confidentiality_access_check }

        it 'returns all issues' do
          expect(subject).to include(public_issue, confidential_issue)
        end

        it 'does not filter by confidentiality' do
          expect(Issue).not_to receive(:where).with(a_string_matching('confidential'), anything)

          subject
        end
      end

      context 'for an admin' do
        let(:admin_user) { create(:user, :admin) }

        subject { described_class.new(admin_user, params).with_confidentiality_access_check }

        context 'when admin mode is enabled', :enable_admin_mode do
          it 'returns all issues' do
            expect(subject).to include(public_issue, confidential_issue)
          end

          it 'does not filter by confidentiality' do
            expect(Issue).not_to receive(:where).with(a_string_matching('confidential'), anything)

            subject
          end
        end

        context 'when admin mode is disabled' do
          it 'returns only public issues' do
            expect(subject).to include(public_issue)
            expect(subject).not_to include(confidential_issue)
          end

          it 'filters by confidentiality' do
            expect(subject.to_sql).to match("issues.confidential")
          end
        end
      end
    end
  end

  describe '#use_cte_for_search?' do
    let(:finder) { described_class.new(nil, params) }

    context 'when there is no search param' do
      let(:params) { { attempt_group_search_optimizations: true } }

      it 'returns false' do
        expect(finder.use_cte_for_search?).to be_falsey
      end
    end

    context 'when the force_cte param is falsey' do
      let(:params) { { search: 'foo' } }

      it 'returns false' do
        expect(finder.use_cte_for_search?).to be_falsey
      end
    end

    context 'when all conditions are met' do
      context "uses group search optimization" do
        let(:params) { { search: 'foo', attempt_group_search_optimizations: true } }

        it 'returns true' do
          expect(finder.use_cte_for_search?).to be_truthy
          expect(finder.execute.to_sql).to match(/^WITH "issues" AS #{Gitlab::Database::AsWithMaterialized.materialized_if_supported}/)
        end
      end

      context "uses project search optimization" do
        let(:params) { { search: 'foo', attempt_project_search_optimizations: true } }

        it 'returns true' do
          expect(finder.use_cte_for_search?).to be_truthy
          expect(finder.execute.to_sql).to match(/^WITH "issues" AS #{Gitlab::Database::AsWithMaterialized.materialized_if_supported}/)
        end
      end
    end
  end

  describe '#parent_param=' do
    let(:finder) { described_class.new(nil) }

    subject { finder.parent_param = obj }

    where(:klass, :param) do
      :Project | :project_id
      :Group   | :group_id
    end

    with_them do
      let(:obj) { Object.const_get(klass, false).new }

      it 'sets the params' do
        subject

        expect(finder.params[param]).to eq(obj)
      end
    end

    context 'unexpected parent' do
      let(:obj) { MergeRequest.new }

      it 'raises an error' do
        expect { subject }.to raise_error('Unexpected parent: MergeRequest')
      end
    end
  end
end
