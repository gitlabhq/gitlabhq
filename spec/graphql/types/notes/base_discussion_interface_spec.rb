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
    it 'includes :ai_workflows scope for the applicable fields' do
      reply_id_field = described_class.fields['replyId']
      expect(reply_id_field.instance_variable_get(:@scopes)).to include(:ai_workflows)

      resolved_field = described_class.fields['resolved']
      expect(resolved_field.instance_variable_get(:@scopes)).to include(:ai_workflows)

      resolvable_field = described_class.fields['resolvable']
      expect(resolvable_field.instance_variable_get(:@scopes)).to include(:ai_workflows)

      id_field = described_class.fields['id']
      expect(id_field.instance_variable_get(:@scopes)).to include(:ai_workflows)
    end
  end
end
