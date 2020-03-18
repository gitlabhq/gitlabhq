# frozen_string_literal: true
require 'spec_helper'

describe GitlabSchema.types['Discussion'] do
  it { expect(described_class).to have_graphql_fields(:id, :created_at, :notes, :reply_id) }

  it { expect(described_class).to require_graphql_authorizations(:read_note) }
end
