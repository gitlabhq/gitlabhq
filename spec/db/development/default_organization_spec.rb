# frozen_string_literal: true

require 'spec_helper'
require './lib/gitlab/faker/internet'

# https://gitlab.com/gitlab-org/gitlab/-/work_items/499203
RSpec.describe 'seed development fixtures without the default organization', :silence_stdout,
  feature_category: :cell do
  let(:fixture_paths) { [Rails.root.join('db/fixtures/development').to_s] }
  let(:claim_service) { Gitlab::TopologyServiceClient::ClaimService.instance }
  let(:lease_response) do
    Gitlab::Cells::TopologyService::Claims::V1::BeginUpdateResponse.new(
      lease_uuid: Gitlab::Cells::TopologyService::Types::V1::UUID.new(value: SecureRandom.uuid))
  end

  subject(:seed) do
    SeedFu.seed(
      fixture_paths, /01__default_organization|01_admin|18_abuse_reports|25_api_personal_access_token/
    )
  end

  before do
    stub_config_cell(enabled: true, id: 2)
    allow(Current).to receive(:cells_claims_leases?).and_return(true)

    allow(claim_service).to receive(:commit_update)
    allow(claim_service).to receive(:begin_update) do |create_records:, **|
      if create_records.any? { |record| record[:claim] == { organization_path: 'default' } }
        raise GRPC::AlreadyExists, 'claim conflict {ORGANIZATION_PATH=default}'
      end

      lease_response
    end
  end

  it 'seeds users and an API token in the organization of the per-cell administrator', :aggregate_failures do
    seed

    admin = User.admins.order(:id).first
    organization = admin.organization

    expect(organization).not_to be_default
    expect(admin.username).to match(/\Aroot-cell-2-\h{8}\z/)
    expect(User.where.not(organization_id: organization.id)).to be_empty
    expect(User.where.not(id: admin.id)).to be_present
    expect(admin.personal_access_tokens.find_by(name: 'seeded-api-token')).to be_present
  end
end
