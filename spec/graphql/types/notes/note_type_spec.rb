# frozen_string_literal: true
require 'spec_helper'

describe GitlabSchema.types['Note'] do
  it 'exposes the expected fields' do
    expected_fields = [:id, :project, :author, :body, :created_at,
                       :updated_at, :discussion, :resolvable, :position, :user_permissions,
                       :resolved_by, :resolved_at, :system, :body_html]

    is_expected.to have_graphql_fields(*expected_fields)
  end

  it { is_expected.to expose_permissions_using(Types::PermissionTypes::Note) }
  it { is_expected.to require_graphql_authorizations(:read_note) }
end
