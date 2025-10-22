# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Notes::Create::Note, feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let(:scope_validator) { instance_double(Gitlab::Auth::ScopeValidator, valid_for?: true) }
  let(:query) { GraphQL::Query.new(empty_schema, document: nil, context: {}, variables: {}) }
  let(:params) { { noteable_id: issue.to_gid, body: 'A test note' } }
  let(:query_context) do
    GraphQL::Query::Context.new(
      query: query,
      values: { current_user: user, scope_validator: scope_validator }
    )
  end

  let_it_be(:user) { create(:user, developer_of: project) }
  let_it_be(:issue) { create(:issue, project: project) }

  subject(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  before do
    allow(Gitlab::Auth::ScopeValidator).to receive(:new).and_return(scope_validator)
  end

  it 'passes scope_validator from context to the CreateService' do
    expect(::Notes::CreateService).to receive(:new).with(
      project,
      user,
      hash_including(scope_validator: scope_validator)
    ).and_call_original

    mutation.resolve(params)
  end
end
