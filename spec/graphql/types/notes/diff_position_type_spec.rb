# frozen_string_literal: true
require 'spec_helper'

describe GitlabSchema.types['DiffPosition'] do
  it 'exposes the expected fields' do
    expected_fields = [:diff_refs, :file_path, :old_path,
                       :new_path, :position_type, :old_line, :new_line, :x, :y,
                       :width, :height]

    is_expected.to have_graphql_field(*expected_fields)
  end
end
