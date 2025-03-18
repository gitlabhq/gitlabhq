# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ActivityStream'], feature_category: :user_profile do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }

  before_all do
    project.add_developer(current_user)
  end

  specify { expect(described_class.graphql_name).to eq('ActivityStream') }

  specify { expect(described_class).to require_graphql_authorizations(:read_user_profile) }

  it 'exposes the expected fields' do
    expected_fields = %i[followed_users_activity]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe "#followed_users_activity" do
    let_it_be(:followed_user) { create(:user) }
    let_it_be(:joined_project_event) { create(:event, :joined, project: project, author: followed_user) }
    let_it_be(:issue) { create(:issue, project: project) }
    let_it_be(:closed_issue_event) { create(:event, :closed, author: followed_user, project: project, target: issue) }
    let(:scope) { current_user.followees }
    let(:filter) { EventFilter.new('ALL') }
    let(:params) { { limit: 20 } }
    let(:field) { resolve_field(:followed_users_activity, current_user, ctx: { current_user: current_user }) }

    before do
      current_user.follow(followed_user)
    end

    it 'calls UserRecentEventsFinder' do
      expect_next_instance_of(UserRecentEventsFinder, current_user, scope, filter, params) do |finder|
        expect(finder).to receive(:execute).and_call_original
      end
      expect(field.items.length).to be(2)
      expect(field.items.first.action).to eq "closed"
      expect(field.items.second.action).to eq "joined"
    end
  end
end
