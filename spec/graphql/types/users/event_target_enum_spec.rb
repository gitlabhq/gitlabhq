# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['EventTarget'], feature_category: :user_profile do
  specify { expect(described_class.graphql_name).to eq('EventTarget') }

  it 'exposes all the existing event target types' do
    expected = EventFilter.new('').filters.map(&:upcase) # varies between foss/ee
    expect(described_class.values.keys).to match_array(expected)
  end
end
