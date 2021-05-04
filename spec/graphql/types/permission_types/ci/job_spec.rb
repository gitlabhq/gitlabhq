# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::PermissionTypes::Ci::Job do
  it 'has expected permission fields' do
    expected_permissions = [
      :read_job_artifacts, :read_build, :update_build
    ]

    expect(described_class).to have_graphql_fields(expected_permissions).only
  end
end
