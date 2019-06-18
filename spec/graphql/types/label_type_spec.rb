# frozen_string_literal: true
require 'spec_helper'

describe GitlabSchema.types['Label'] do
  it { is_expected.to require_graphql_authorizations(:read_label) }
end
