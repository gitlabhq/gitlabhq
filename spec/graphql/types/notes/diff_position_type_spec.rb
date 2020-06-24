# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DiffPosition'] do
  it 'exposes the expected fields' do
    expected_fields = %i[
      diff_refs
      file_path
      height
      new_line
      new_path
      old_line
      old_path
      position_type
      width
      x
      y
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
