# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Suggestion'], feature_category: :code_review_workflow do
  it 'exposes the expected fields' do
    expected_fields = %i[
      id
      applied
      from_line
      to_line
      from_content
      to_content
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
