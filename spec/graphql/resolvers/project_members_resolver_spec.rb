# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Resolvers::ProjectMembersResolver', feature_category: :user_management do
  include GraphqlHelpers

  let(:described_class) { Resolvers::ProjectMembersResolver }

  it_behaves_like 'querying members with a group' do
    let_it_be(:project) { create(:project, group: group_1) }
    let_it_be(:resource_member) { create(:project_member, :owner, user: user_1, project: project) }
    let_it_be(:resource) { project }
  end

  context 'when user_types are passed' do
    it 'returns all users who match', :aggregate_failures do
      group = create(:group)
      human = create(:user)
      service_account = create(:user, :service_account)
      project_bot = create(:user, :project_bot)
      project = create(:project, group: group, developers: [human, service_account, project_bot])

      results = resolve(
        described_class, obj: project, ctx: { current_user: human }, args: { user_types: %w[service_account human] }
      )

      expect(results.map(&:user)).to contain_exactly(service_account, human)
    end
  end
end
