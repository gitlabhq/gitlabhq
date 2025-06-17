# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['TodoTargetEnum'], feature_category: :notifications do
  specify { expect(described_class.graphql_name).to eq('TodoTargetEnum') }

  it 'exposes all TodosFinder.todo_types as a value' do
    expect(described_class.values.values).to match_array(
      ::TodosFinder.todo_types.map do |class_name|
        have_attributes(value: class_name)
      end
    )
  end
end
