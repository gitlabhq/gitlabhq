# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiVariableInput'] do
  include GraphqlHelpers

  it 'has the correct arguments' do
    expect(described_class.arguments.keys).to match_array(%w[key value variableType])
  end
end
