# frozen_string_literal: true
require 'spec_helper'

describe GitlabSchema.types['Discussion'] do
  it { is_expected.to have_graphql_fields(:id, :created_at, :notes, :reply_id) }

  it { is_expected.to require_graphql_authorizations(:read_note) }
end
