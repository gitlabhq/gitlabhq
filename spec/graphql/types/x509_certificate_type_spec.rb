# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['X509Certificate'] do
  specify { expect(described_class.graphql_name).to eq('X509Certificate') }

  it 'contains attributes for X.509 certifcates' do
    expect(described_class).to have_graphql_fields(
      :certificate_status, :created_at, :email, :id, :serial_number, :subject,
      :subject_key_identifier, :updated_at, :x509_issuer
    )
  end
end
