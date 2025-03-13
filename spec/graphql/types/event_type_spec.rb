# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::EventType do
  specify { expect(described_class.graphql_name).to eq('Event') }

  specify { expect(described_class).to require_graphql_authorizations(:read_event) }

  specify do
    expect(described_class).to have_graphql_fields(:id, :author, :action, :project, :target, :created_at, :updated_at)
  end
end
