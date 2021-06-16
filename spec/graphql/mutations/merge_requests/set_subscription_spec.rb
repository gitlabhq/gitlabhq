# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::MergeRequests::SetSubscription do
  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:resource) { create(:merge_request, source_project: project, target_project: project) }

  specify { expect(described_class).to require_graphql_authorizations(:update_subscription) }

  context 'when user does not have access to the project' do
    it_behaves_like 'a subscribeable not accessible graphql resource'
  end

  context 'when user is developer member of the project' do
    before do
      project.add_developer(user)
    end

    it_behaves_like 'a subscribeable graphql resource'
  end

  context 'when the project is public' do
    before do
      project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
    end

    it_behaves_like 'a subscribeable graphql resource'
  end
end
