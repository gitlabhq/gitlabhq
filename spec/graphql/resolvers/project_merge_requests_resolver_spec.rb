# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ProjectMergeRequestsResolver do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user, developer_of: project) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:reviewer) { create(:user) }
  let_it_be(:label) { create(:label, project: project) }

  let_it_be(:merge_request) do
    create(
      :merge_request,
      :unique_branches,
      source_project: project,
      target_project: project,
      author: other_user,
      assignee: other_user,
      milestone: create(:milestone, project: project),
      reviewers: [reviewer],
      labels: [label]
    )
  end

  let_it_be(:merge_request2) do
    create(
      :merge_request,
      :unique_branches,
      source_project: project,
      target_project: project,
      author: other_user
    )
  end

  context 'by assignee' do
    it 'filters merge requests by assignee username' do
      result = resolve_mr(project, assignee_username: other_user.username)

      expect(result).to contain_exactly(merge_request)
    end

    it 'does not find anything' do
      result = resolve_mr(project, assignee_username: 'unknown-user')

      expect(result).to be_empty
    end
  end

  context 'by author' do
    it 'filters merge requests by author username' do
      result = resolve_mr(project, author_username: other_user.username)

      expect(result).to contain_exactly(merge_request, merge_request2)
    end

    it 'does not find anything' do
      result = resolve_mr(project, author_username: 'unknown-user')

      expect(result).to be_empty
    end
  end

  context 'by reviewer' do
    it 'filters merge requests by reviewer username' do
      result = resolve_mr(project, reviewer_username: reviewer.username)

      expect(result).to contain_exactly(merge_request)
    end

    it 'does not find anything' do
      result = resolve_mr(project, reviewer_username: 'unknown-user')

      expect(result).to be_empty
    end
  end

  context 'with reviewer wildcard param' do
    it 'filters merge requests by NONE wildcard' do
      result = resolve_mr(project, reviewer_wildcard_id: 'NONE')

      expect(result).to contain_exactly(merge_request2)
    end

    it 'filters merge requests by ANY wildcard' do
      result = resolve_mr(project, reviewer_wildcard_id: 'ANY')

      expect(result).to contain_exactly(merge_request)
    end

    it 'returns error when assignee username and wildcard id are used' do
      expect_graphql_error_to_be_created(GraphQL::Schema::Validator::ValidationFailedError,
        'Only one of [reviewerUsername, reviewerWildcardId] arguments is allowed at the same time.') do
        resolve_mr(project, reviewer_username: current_user.username, reviewer_wildcard_id: 'ANY')
      end
    end
  end

  context 'with assignee wildcard param' do
    it 'filters merge requests by NONE wildcard' do
      result = resolve_mr(project, assignee_wildcard_id: 'NONE')

      expect(result).to contain_exactly(merge_request2)
    end

    it 'filters merge requests by ANY wildcard' do
      result = resolve_mr(project, assignee_wildcard_id: 'ANY')

      expect(result).to contain_exactly(merge_request)
    end

    it 'returns error when assignee username and wildcard id are used' do
      expect_graphql_error_to_be_created(GraphQL::Schema::Validator::ValidationFailedError,
        'Only one of [assigneeUsername, assigneeWildcardId] arguments is allowed at the same time.') do
        resolve_mr(project, assignee_username: current_user.username, assignee_wildcard_id: 'ANY')
      end
    end
  end

  context 'with milestone wildcard param' do
    it 'filters merge requests by NONE wildcard' do
      result = resolve_mr(project, milestone_wildcard_id: 'NONE')

      expect(result).to contain_exactly(merge_request2)
    end

    it 'filters merge requests by ANY wildcard' do
      result = resolve_mr(project, milestone_wildcard_id: 'ANY')

      expect(result).to contain_exactly(merge_request)
    end

    it 'returns error when milestone title and wildcard id are used' do
      expect_graphql_error_to_be_created(GraphQL::Schema::Validator::ValidationFailedError,
        'Only one of [milestoneTitle, milestoneWildcardId] arguments is allowed at the same time.') do
        resolve_mr(project, milestone_title: 'test', milestone_wildcard_id: 'ANY')
      end
    end
  end

  context 'with label name param' do
    it 'filters merge requests by label name' do
      result = resolve_mr(project, label_name: [label.name])

      expect(result).to contain_exactly(merge_request)
    end
  end

  context 'with negated params' do
    context 'with negated assignee username' do
      it do
        result = resolve_mr(project, not: { assignee_usernames: [other_user.username] })

        expect(result).to contain_exactly(merge_request2)
      end
    end

    context 'with negated reviewer username' do
      it do
        result = resolve_mr(project, not: { reviewer_username: reviewer.username })

        expect(result).to contain_exactly(merge_request2)
      end
    end

    context 'with negated review states' do
      let_it_be(:merge_request3) do
        create(
          :merge_request,
          :unique_branches,
          source_project: project,
          target_project: project,
          author: other_user,
          reviewers: [reviewer]
        )
      end

      before_all do
        merge_request3.merge_request_reviewers.update_all(state: :requested_changes)
      end

      it do
        result = resolve_mr(project, not: { review_states: ['REQUESTED_CHANGES'] })

        expect(result).to contain_exactly(merge_request)
      end
    end
  end

  def resolve_mr(project, resolver: described_class, user: current_user, **args)
    resolve(resolver, obj: project, args: args, ctx: { current_user: user })
  end
end
