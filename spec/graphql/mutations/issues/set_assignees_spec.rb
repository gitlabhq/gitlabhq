# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Issues::SetAssignees, feature_category: :api do
  include GraphqlHelpers
  context 'when the user does not have permissions' do
    let_it_be(:issue) { create(:issue) }
    let_it_be(:user) { create(:user) }
    let_it_be(:assignee) { create(:user) }

    let(:query) { GraphQL::Query.new(empty_schema, document: nil, context: {}, variables: {}) }
    let(:context) { GraphQL::Query::Context.new(query: query, values: { current_user: user }) }

    subject(:mutation) { described_class.new(object: nil, context: context, field: nil) }

    describe '#resolve' do
      subject do
        mutation.resolve(
          project_path: issue.project.full_path,
          iid: issue.iid,
          operation_mode: Types::MutationOperationModeEnum.default_mode,
          assignee_usernames: [assignee.username]
        )
      end

      it_behaves_like 'permission level for issue mutation is correctly verified'
    end
  end

  it_behaves_like 'an assignable resource' do
    let_it_be(:resource, reload: true) { create(:issue) }
  end
end
