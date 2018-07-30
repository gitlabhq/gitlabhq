# frozen_string_literal: true

require 'spec_helper'

describe SoftwareLicensePolicies::UpdateService do
  let(:project) { create(:project)}

  let(:user) do
    create(:user).tap do |u|
      project.add_maintainer(u)
    end
  end

  let(:software_license_policy) do
    create(
      :software_license_policy,
      software_license: create(:software_license, name: 'ExamplePL/2.1'),
      approval_status: 'blacklisted'
    )
  end

  before do
    stub_licensed_features(license_management: true)
  end

  describe '#execute' do
    def update_software_license_policy(opts)
      described_class.new(project, user, opts).execute(software_license_policy)
    end

    context 'approval status update' do
      let(:opts) do
        { approval_status: 'approved' }
      end

      context 'with license management unavailable' do
        before do
          stub_licensed_features(license_management: false)
        end

        it 'does not update the software license policy' do
          update_software_license_policy(opts)

          expect(software_license_policy).to be_valid
          expect(software_license_policy.approval_status).not_to eq(opts[:approval_status])
        end
      end

      context 'with a user allowed to admin' do
        it 'updates the software license policy correctly' do
          update_software_license_policy(opts)

          expect(software_license_policy).to be_valid
          expect(software_license_policy.approval_status).to eq(opts[:approval_status])
        end
      end

      context 'with a user not allowed to admin' do
        let(:user) { create(:user) }

        it 'does not updates the software license policy' do
          update_software_license_policy(opts)

          expect(software_license_policy).to be_valid
          expect(software_license_policy.approval_status).not_to eq(opts[:approval_status])
        end
      end
    end

    context 'name update' do
      let(:opts) do
        { name: 'MyPL' }
      end

      it 'does not updates the software license policy' do
        update_software_license_policy(opts)

        expect(software_license_policy).to be_valid
        expect(software_license_policy.name).not_to eq(opts[:name])
      end
    end
  end
end
