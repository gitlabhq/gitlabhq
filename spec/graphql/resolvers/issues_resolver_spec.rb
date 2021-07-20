# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::IssuesResolver do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  let_it_be(:group)         { create(:group) }
  let_it_be(:project)       { create(:project, group: group) }
  let_it_be(:other_project) { create(:project, group: group) }

  let_it_be(:milestone) { create(:milestone, project: project) }
  let_it_be(:assignee)  { create(:user) }
  let_it_be(:issue1)    { create(:incident, project: project, state: :opened, created_at: 3.hours.ago, updated_at: 3.hours.ago, milestone: milestone) }
  let_it_be(:issue2)    { create(:issue, project: project, state: :closed, title: 'foo', created_at: 1.hour.ago, updated_at: 1.hour.ago, closed_at: 1.hour.ago, assignees: [assignee]) }
  let_it_be(:issue3)    { create(:issue, project: other_project, state: :closed, title: 'foo', created_at: 1.hour.ago, updated_at: 1.hour.ago, closed_at: 1.hour.ago, assignees: [assignee]) }
  let_it_be(:issue4)    { create(:issue) }
  let_it_be(:label1)    { create(:label, project: project) }
  let_it_be(:label2)    { create(:label, project: project) }

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::IssueType.connection_type)
  end

  context "with a project" do
    before_all do
      project.add_developer(current_user)
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
        expect(resolve_issues(milestone_title: [milestone.title])).to contain_exactly(issue1)
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
          it 'raises a mutually exclusive filter error' do
            expect do
              resolve_issues(assignee_usernames: [assignee.username], assignee_username: assignee.username)
            end.to raise_error(Gitlab::Graphql::Errors::ArgumentError, 'only one of [assigneeUsernames, assigneeUsername] arguments is allowed at the same time.')
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

      context 'when searching issues' do
        it 'returns correct issues' do
          expect(resolve_issues(search: 'foo')).to contain_exactly(issue2)
        end

        it 'uses project search optimization' do
          expected_arguments = a_hash_including(
            search: 'foo',
            attempt_project_search_optimizations: true
          )
          expect(IssuesFinder).to receive(:new).with(anything, expected_arguments).and_call_original

          resolve_issues(search: 'foo')
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
          expect(resolve_issues(not: { milestone_title: [milestone.title] })).to contain_exactly(issue2)
        end

        it 'returns issues without the specified assignee_usernames' do
          expect(resolve_issues(not: { assignee_usernames: [assignee.username] })).to contain_exactly(issue1)
        end

        it 'returns issues without the specified assignee_id' do
          expect(resolve_issues(not: { assignee_id: [assignee.id] })).to contain_exactly(issue1)
        end
      end

      describe 'sorting' do
        context 'when sorting by created' do
          it 'sorts issues ascending' do
            expect(resolve_issues(sort: 'created_asc').to_a).to eq [issue1, issue2]
          end

          it 'sorts issues descending' do
            expect(resolve_issues(sort: 'created_desc').to_a).to eq [issue2, issue1]
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
            expect(resolve_issues(sort: :relative_position_asc).to_a).to eq [relative_issue3, relative_issue1, relative_issue4, relative_issue2]
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

        context 'when sorting with non-stable cursors' do
          %i[priority_asc priority_desc
             popularity_asc popularity_desc
             label_priority_asc label_priority_desc
             milestone_due_asc milestone_due_desc].each do |sort_by|
            it "uses offset-pagination when sorting by #{sort_by}" do
              resolved = resolve_issues(sort: sort_by)

              expect(resolved).to be_a(::Gitlab::Graphql::Pagination::OffsetActiveRecordRelationConnection)
            end
          end
        end
      end

      it 'returns issues user can see' do
        project.add_guest(current_user)

        create(:issue, confidential: true)

        expect(resolve_issues).to contain_exactly(issue1, issue2)
      end

      it 'finds a specific issue with iid', :request_store do
        result = batch_sync(max_queries: 4) { resolve_issues(iid: issue1.iid).to_a }

        expect(result).to contain_exactly(issue1)
      end

      it 'batches queries that only include IIDs', :request_store do
        result = batch_sync(max_queries: 4) do
          [issue1, issue2]
            .map { |issue| resolve_issues(iid: issue.iid.to_s) }
            .flat_map(&:to_a)
        end

        expect(result).to contain_exactly(issue1, issue2)
      end

      it 'finds a specific issue with iids', :request_store do
        result = batch_sync(max_queries: 4) do
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

  context "with a group" do
    before do
      group.add_developer(current_user)
    end

    describe '#resolve' do
      it 'finds all group issues' do
        result = resolve(described_class, obj: group, ctx: { current_user: current_user })

        expect(result).to contain_exactly(issue1, issue2, issue3)
      end
    end
  end

  context "when passing a non existent, batch loaded project" do
    let(:project) do
      BatchLoader::GraphQL.for("non-existent-path").batch do |_fake_paths, loader, _|
        loader.call("non-existent-path", nil)
      end
    end

    it "returns nil without breaking" do
      expect(resolve_issues(iids: ["don't", "break"])).to be_empty
    end
  end

  it 'increases field complexity based on arguments' do
    field = Types::BaseField.new(name: 'test', type: GraphQL::STRING_TYPE.connection_type, resolver_class: described_class, null: false, max_page_size: 100)

    expect(field.to_graphql.complexity.call({}, {}, 1)).to eq 4
    expect(field.to_graphql.complexity.call({}, { labelName: 'foo' }, 1)).to eq 8
  end

  def create_issue_with_severity(project, severity:)
    issue = create(:incident, project: project)
    create(:issuable_severity, issue: issue, severity: severity)

    issue
  end

  def resolve_issues(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: project, args: args, ctx: context)
  end
end
