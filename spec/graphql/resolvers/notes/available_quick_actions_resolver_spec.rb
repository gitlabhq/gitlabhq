# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Notes::AvailableQuickActionsResolver, feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, developers: user) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  subject(:resolved) { resolve(described_class, obj: merge_request, ctx: { current_user: current_user }) }

  context 'when there is a current user with access' do
    let(:current_user) { user }

    it 'returns the quick action commands available on the merge request' do
      names = resolved.map { |command| command[:name] }

      expect(names).to include(:assign, :close, :merge, :title)
    end

    it 'shapes each command with the expected keys' do
      expect(resolved).to all(include(:name, :aliases, :description, :params, :warning, :icon))
    end

    it 'resolves command aliases' do
      request_review = resolved.find { |command| command[:name] == :request_review }

      expect(request_review[:aliases]).to include(:assign_reviewer, :reviewer)
    end
  end

  context 'when there is no current user' do
    let(:current_user) { nil }

    it { is_expected.to eq([]) }
  end

  context 'when the current user only has guest access' do
    let_it_be(:guest) { create(:user, guest_of: project) }

    let(:current_user) { guest }

    it 'excludes commands that require permissions above guest' do
      names = resolved.map { |command| command[:name] }

      expect(names).not_to include(:submit_review)
    end
  end

  context 'when the current user is a bot type that is not permitted to use quick actions' do
    let_it_be(:security_bot) { create(:user, :security_bot, maintainer_of: project) }

    let(:current_user) { security_bot }

    it 'returns no commands' do
      expect(current_user.can?(:use_quick_actions)).to be(false)
      expect(resolved).to eq([])
    end
  end

  context 'when the noteable is an issue' do
    let_it_be(:issue) { create(:issue, project: project) }

    let(:current_user) { user }

    subject(:resolved) { resolve(described_class, obj: issue, ctx: { current_user: current_user }) }

    it 'returns issue commands and excludes merge-request-only ones' do
      names = resolved.map { |command| command[:name] }

      expect(names).to include(:assign, :close, :title, :todo)
      expect(names).not_to include(:merge)
    end

    it 'shapes each command with the expected keys' do
      expect(resolved).to all(include(:name, :aliases, :description, :params, :warning, :icon))
    end
  end

  context 'when the noteable is a project-level work item' do
    let_it_be(:work_item) { create(:work_item, :task, project: project) }

    let(:current_user) { user }

    subject(:resolved) { resolve(described_class, obj: work_item, ctx: { current_user: current_user }) }

    it 'returns work item commands and excludes merge-request-only ones' do
      names = resolved.map { |command| command[:name] }

      expect(names).to include(:close, :title, :todo)
      expect(names).not_to include(:merge)
    end
  end
end
