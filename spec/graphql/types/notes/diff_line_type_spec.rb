# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DiffLine'], feature_category: :code_review_workflow do
  it 'exposes the expected fields' do
    expected_fields = %i[
      can_receive_suggestion
      line_code
      new_line
      old_line
      rich_text
      text
      type
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
