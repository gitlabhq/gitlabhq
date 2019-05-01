# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['Namespace'] do
  it { expect(described_class.graphql_name).to eq('Namespace') }
end
