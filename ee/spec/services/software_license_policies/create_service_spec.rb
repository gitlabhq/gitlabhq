# frozen_string_literal: true

require 'spec_helper'

describe SoftwareLicensePolicies::CreateService do
  let(:project) { create(:project)}
  let(:params) { { name: 'ExamplePL/2.1', approval_status: 'blacklisted' } }

  let(:user) do
    create(:user).tap do |u|
      project.add_maintainer(u)
    end
  end

  before do
    stub_licensed_features(license_management: true)
  end

  subject { described_class.new(project, user, params).execute }

  describe '#execute' do
    context 'with license management unavailable' do
      before do
        stub_licensed_features(license_management: false)
      end

      it 'does not creates a software license policy' do
        expect { subject }.to change { project.software_license_policies.count }.by(0)
      end
    end

    context 'with a user who is allowed to admin' do
      it 'creates one software license policy correctly' do
        expect { subject }.to change { project.software_license_policies.count }.from(0).to(1)

        software_license_policy = project.software_license_policies.last
        expect(software_license_policy).to be_persisted
        expect(software_license_policy.name).to eq('ExamplePL/2.1')
        expect(software_license_policy.approval_status).to eq('blacklisted')
      end
    end

    context 'with a user not allowed to admin' do
      let(:user) { create(:user) }

      it 'does not create a software license policy' do
        expect { subject }.to change { project.software_license_policies.count }.by(0)
      end
    end
  end
end
