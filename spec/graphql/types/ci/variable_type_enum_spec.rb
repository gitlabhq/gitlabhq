# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiVariableType'] do
  it 'matches the keys of Ci::Variable.variable_types' do
    expect(described_class.values.keys).to contain_exactly('ENV_VAR', 'FILE')
  end
end
