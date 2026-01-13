# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Notes::BaseDiscussionInterface, feature_category: :team_planning do
  it 'exposes the expected fields' do
    expected_fields = %i[
      created_at
      id
      reply_id
      resolvable
      resolved
      resolved_at
      resolved_by
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe 'fields with :ai_workflows scope' do
    it 'includes :ai_workflows scope for the reply_id field' do
      field = described_class.fields['replyId']
      expect(field.instance_variable_get(:@scopes)).to include(:ai_workflows)
    end
  end
end
