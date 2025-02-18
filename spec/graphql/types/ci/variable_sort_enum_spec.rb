# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::VariableSortEnum, feature_category: :ci_variables do
  it 'exposes the available order methods' do
    expect(described_class.values).to match(
      'KEY_ASC' => have_attributes(value: :key_asc),
      'KEY_DESC' => have_attributes(value: :key_desc)
    )
  end
end
