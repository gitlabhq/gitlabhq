require 'spec_helper'

describe BasePolicy do
  include ExternalAuthorizationServiceHelpers

  let(:current_user) { create(:user) }
  let(:user) { create(:user) }

  subject { described_class.new(current_user, [user]) }

  describe 'read cross project' do
    it { is_expected.to be_allowed(:read_cross_project) }

    context 'when an external authorization service is enabled' do
      before do
        enable_external_authorization_service_check
      end

      it { is_expected.not_to be_allowed(:read_cross_project) }

      it 'allows admins' do
        expect(described_class.new(build(:admin), nil)).to be_allowed(:read_cross_project)
      end

      it 'allows auditors' do
        expect(described_class.new(build(:auditor), nil)).to be_allowed(:read_cross_project)
      end
    end
  end
end
