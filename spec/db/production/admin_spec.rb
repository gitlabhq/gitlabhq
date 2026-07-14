# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'seed production admin', feature_category: :organization do
  let(:admin_fixture) { Rails.root.join('db/fixtures/production/003_admin.rb') }

  subject(:load_fixture) { load(admin_fixture) }

  context 'when the default organization exists (single-cell or legacy cell)' do
    # rubocop:disable Gitlab/RSpec/AvoidCreateDefaultOrganization -- exercising the default-organization path
    let_it_be(:default_organization) { create(:organization, :default) }
    # rubocop:enable Gitlab/RSpec/AvoidCreateDefaultOrganization

    it 'seeds a root administrator owning the default organization, without creating an organization',
      :aggregate_failures do
      expect { load_fixture }
        .to change { User.admins.count }.by(1)
        .and not_change { Organizations::Organization.count }

      admin = User.admins.order(:id).last
      expect(admin.username).to eq('root')
      expect(default_organization.owner?(admin)).to be(true)
    end
  end

  context 'when the default organization is absent (non-owning cell)' do
    before do
      stub_config_cell(id: 2)
    end

    it 'creates a per-cell organization and a per-cell administrator that owns it', :aggregate_failures do
      expect { load_fixture }
        .to change { User.admins.count }.by(1)
        .and change { Organizations::Organization.count }.by(1)

      admin = User.admins.order(:id).last
      organization = Organizations::Organization.order(:id).last

      expect(admin.username).to match(/\Aroot-cell-2-\h{8}\z/)
      expect(organization).not_to be_default
      expect(organization.path).to match(/\Aadmin-org-cell-2-\h{8}\z/)
      expect(organization.owner?(admin)).to be(true)
    end

    context 'when the admin env vars are set' do
      before do
        stub_env('GITLAB_ROOT_USERNAME' => 'cell-2-admin')
        stub_env('GITLAB_ROOT_ORG_PATH' => 'cell-2-org')
      end

      it 'uses them instead of the derived values', :aggregate_failures do
        load_fixture

        expect(User.admins.order(:id).last.username).to eq('cell-2-admin')
        expect(Organizations::Organization.order(:id).last.path).to eq('cell-2-org')
      end
    end
  end

  context 'when an administrator already exists' do
    let_it_be(:existing_admin) { create(:admin) }

    it 'skips creation and creates no organization' do
      expect { load_fixture }
        .to not_change { User.admins.count }
        .and not_change { Organizations::Organization.count }
    end
  end
end
