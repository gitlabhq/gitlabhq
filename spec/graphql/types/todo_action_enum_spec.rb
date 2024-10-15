# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['TodoActionEnum'], feature_category: :notifications do
  specify { expect(described_class.graphql_name).to eq('TodoActionEnum') }

  it 'exposes all existing Todo::ACTION_NAMES with the same name and value' do
    enum_as_hash = described_class.values.values.to_h do |enum|
      [enum.value, enum.graphql_name.to_sym]
    end
    expect(enum_as_hash).to eq(Todo::ACTION_NAMES)
  end
end
