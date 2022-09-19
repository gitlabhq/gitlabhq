# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Resolvers::ProjectMembersResolver' do
  include GraphqlHelpers

  let(:described_class) { Resolvers::ProjectMembersResolver }

  it_behaves_like 'querying members with a group' do
    let_it_be(:project) { create(:project, group: group_1) }
    let_it_be(:resource_member) { create(:project_member, user: user_1, project: project) }
    let_it_be(:resource) { project }
  end
end
