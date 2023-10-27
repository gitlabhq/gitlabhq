# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::PermissionTypes::AbuseReport, feature_category: :insider_threat do
  it do
    expected_permissions = [
      :read_abuse_report, :create_note
    ]

    expected_permissions.each do |permission|
      expect(described_class).to have_graphql_field(permission)
    end
  end
end
