# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::ResolvableInterface do
  it 'exposes the expected fields' do
    expected_fields = %i[
      resolvable
      resolved
      resolved_at
      resolved_by
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe 'fields with :ai_workflows scope' do
    it 'includes :ai_workflows scope for the applicable fields' do
      resolved_field = described_class.fields['resolved']
      expect(resolved_field.instance_variable_get(:@scopes)).to include(:ai_workflows)

      resolvable_field = described_class.fields['resolvable']
      expect(resolvable_field.instance_variable_get(:@scopes)).to include(:ai_workflows)
    end
  end
end
