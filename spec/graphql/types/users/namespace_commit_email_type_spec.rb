# frozen_string_literal: true
require 'spec_helper'

RSpec.describe GitlabSchema.types['NamespaceCommitEmail'], feature_category: :user_profile do
  it 'has the correct fields' do
    expected_fields = [
      :id,
      :email,
      :namespace,
      :created_at,
      :updated_at
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  specify { expect(described_class).to require_graphql_authorizations(:read_user_email_address) }
end
