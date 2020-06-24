# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DesignManagement'] do
  it { expect(described_class).to have_graphql_fields(:version, :design_at_version) }
end
