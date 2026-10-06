# frozen_string_literal: true

require 'spec_helper'

# The fixtures run via SeedFu.seed rather than `load` because seed-fu wraps each fixture in a joinable
# transaction, and Cells claims are sent when the outermost transaction commits, outside the importer.
# On a cell that does not own the default organization, creating it aborts seeding with
# Cells::TransactionRecord::AlreadyClaimedError raised from seed-fu's commit.
# https://gitlab.com/gitlab-org/gitlab/-/work_items/499203
RSpec.describe 'seed production default organization', :silence_stdout, feature_category: :cell do
  let(:fixture_paths) { [Rails.root.join('db/fixtures/production').to_s] }
  let(:claim_service) { Gitlab::TopologyServiceClient::ClaimService.instance }
  let(:lease_response) do
    Gitlab::Cells::TopologyService::Claims::V1::BeginUpdateResponse.new(
      lease_uuid: Gitlab::Cells::TopologyService::Types::V1::UUID.new(value: SecureRandom.uuid))
  end

  subject(:seed) { SeedFu.seed(fixture_paths, /002_default_organization|003_admin/) }

  context 'when claims are enabled' do
    before do
      stub_config_cell(enabled: true, id: cell_id)
      allow(Current).to receive(:cells_claims_leases?).and_return(true)

      allow(claim_service).to receive(:commit_update)
    end

    context 'on the legacy cell' do
      let(:cell_id) { 1 }

      before do
        allow(claim_service).to receive(:begin_update).and_return(lease_response)
      end

      it 'seeds the default organization and a root administrator owning it', :aggregate_failures do
        expect { seed }
          .to change { Organizations::Organization.count }.by(1)
          .and change { User.admins.count }.by(1)

        organization = Organizations::Organization.order(:id).last
        admin = User.admins.order(:id).last

        expect(organization).to be_default
        expect(organization.path).to eq('default')
        expect(admin.username).to eq('root')
        expect(organization.owner?(admin)).to be(true)
      end
    end

    context 'on another cell, when the legacy cell holds the default organization claims' do
      let(:cell_id) { 2 }

      # rubocop:disable Gitlab/AvoidConstDefaultOrganizationId -- mirrors the id claim of the default organization
      let(:default_claims) do
        [
          { organization_path: 'default' },
          { organization_id: Organizations::Organization::DEFAULT_ORGANIZATION_ID }
        ]
      end
      # rubocop:enable Gitlab/AvoidConstDefaultOrganizationId

      before do
        allow(claim_service).to receive(:begin_update) do |create_records:, **|
          if create_records.any? { |record| default_claims.include?(record[:claim]) }
            raise GRPC::AlreadyExists, 'claim conflict {ORGANIZATION_PATH=default},{ORGANIZATION_ID=1}'
          end

          lease_response
        end
      end

      it 'skips the default organization and seeds a per-cell organization and administrator',
        :aggregate_failures do
        expect { seed }
          .to change { Organizations::Organization.count }.by(1)
          .and change { User.admins.count }.by(1)

        organization = Organizations::Organization.order(:id).last
        admin = User.admins.order(:id).last

        expect(organization).not_to be_default
        expect(organization.path).to match(/\Aadmin-org-cell-2-\h{8}\z/)
        expect(admin.username).to match(/\Aroot-cell-2-\h{8}\z/)
        expect(organization.owner?(admin)).to be(true)
      end
    end
  end

  context 'when claims are disabled (single cell)' do
    it 'seeds the default organization and a root administrator owning it', :aggregate_failures do
      expect(Gitlab::TopologyServiceClient::ClaimService).not_to receive(:instance)

      expect { seed }
        .to change { Organizations::Organization.count }.by(1)
        .and change { User.admins.count }.by(1)

      organization = Organizations::Organization.order(:id).last
      admin = User.admins.order(:id).last

      expect(organization).to be_default
      expect(organization.path).to eq('default')
      expect(admin.username).to eq('root')
      expect(organization.owner?(admin)).to be(true)
    end
  end
end
