# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ProjectMergeRequestsResolver do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:reviewer) { create(:user) }

  let_it_be(:merge_request) do
    create(:merge_request,
           :unique_branches,
           source_project: project,
           target_project: project,
           author: other_user,
           assignee: other_user,
           reviewers: [reviewer])
  end

  before do
    project.add_developer(current_user)
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

      expect(result).to contain_exactly(merge_request)
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

  def resolve_mr(project, resolver: described_class, user: current_user, **args)
    resolve(resolver, obj: project, args: args, ctx: { current_user: user })
  end
end
