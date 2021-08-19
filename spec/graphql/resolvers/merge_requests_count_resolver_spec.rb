# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::MergeRequestsCountResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project1) { create(:project, :repository, :public) }
    let_it_be(:project2) { create(:project, :repository, repository_access_level: ProjectFeature::PRIVATE) }
    let_it_be(:issue) { create(:issue, project: project1) }
    let_it_be(:merge_request_closing_issue1) { create(:merge_requests_closing_issues, issue: issue) }
    let_it_be(:merge_request_closing_issue2) do
      merge_request = create(:merge_request, source_project: project2)
      create(:merge_requests_closing_issues, issue: issue, merge_request: merge_request)
    end

    specify do
      expect(described_class).to have_nullable_graphql_type(GraphQL::Types::Int)
    end

    subject { batch_sync { resolve_merge_requests_count(issue) } }

    context "when user can only view an issue's closing merge requests that are public" do
      it 'returns the count of the merge requests closing the issue' do
        expect(subject).to eq(1)
      end
    end

    context "when user can view an issue's closing merge requests that are both public and private" do
      before do
        project2.add_reporter(user)
      end

      it 'returns the count of the merge requests closing the issue' do
        expect(subject).to eq(2)
      end
    end
  end

  def resolve_merge_requests_count(obj)
    resolve(described_class, obj: obj, ctx: { current_user: user })
  end
end
