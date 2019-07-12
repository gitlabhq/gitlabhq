# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['DiffRefs'] do
  it { expect(described_class.graphql_name).to eq('DiffRefs') }

  it { expect(described_class).to have_graphql_fields(:base_sha, :head_sha, :start_sha) }
end
