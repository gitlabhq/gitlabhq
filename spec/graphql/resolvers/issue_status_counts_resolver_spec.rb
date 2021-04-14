# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::IssueStatusCountsResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:issue) { create(:issue, project: project, state: :opened, created_at: 3.hours.ago, updated_at: 3.hours.ago) }
    let_it_be(:incident) { create(:incident, project: project, state: :closed, created_at: 1.hour.ago, updated_at: 1.hour.ago, closed_at: 1.hour.ago) }

    # This issue should not be included in the counts
    let_it_be(:other_project) { create(:project) }
    let_it_be(:other_proj_issue) { create(:issue, state: :opened, project: other_project) }

    let(:parent) { project }
    let(:args) { {} }

    before_all do
      project.add_developer(current_user)
      other_project.add_developer(current_user)
    end

    subject { resolve_issue_status_counts(args) }

    it { is_expected.to be_a(Gitlab::IssuablesCountForState) }
    specify { expect(subject.project).to eq(project) }

    shared_examples 'returns expected results' do
      it 'returns expected results', :aggregate_failures do
        result = resolve_issue_status_counts

        expect(result.all).to eq 2
        expect(result.opened).to eq 1
        expect(result.closed).to eq 1
      end
    end

    it_behaves_like 'returns expected results'

    context 'project used as parent' do
      let(:parent) { project }

      it_behaves_like 'returns expected results'
    end

    context 'group used as parent' do
      let(:parent) { project.group }

      it_behaves_like 'returns expected results'
    end

    it 'filters by search', :aggregate_failures do
      result = resolve_issue_status_counts(search: issue.title)

      expect(result.all).to eq 1
      expect(result.opened).to eq 1
      expect(result.closed).to eq 0
    end

    it 'filters by issue type', :aggregate_failures do
      result = resolve_issue_status_counts(types: ['incident'])

      expect(result.all).to eq 1
      expect(result.opened).to eq 0
      expect(result.closed).to eq 1
    end

    context 'when both assignee_username and assignee_usernames are provided' do
      it 'raises a mutually exclusive filter error' do
        expect do
          resolve_issue_status_counts(assignee_usernames: [current_user.username], assignee_username: current_user.username)
        end.to raise_error(Gitlab::Graphql::Errors::ArgumentError, 'only one of [assigneeUsernames, assigneeUsername] arguments is allowed at the same time.')
      end
    end

    private

    def resolve_issue_status_counts(args = {}, context = { current_user: current_user })
      resolve(described_class, obj: parent, args: args, ctx: context)
    end
  end
end
