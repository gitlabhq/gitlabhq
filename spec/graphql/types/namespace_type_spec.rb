# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['Namespace'] do
  it { expect(described_class.graphql_name).to eq('Namespace') }

  it { expect(described_class).to have_graphql_field(:projects) }
end
