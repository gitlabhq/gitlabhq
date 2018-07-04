require 'spec_helper'

describe ApplicationSettings::UpdateService do
  include ExternalAuthorizationServiceHelpers

  let(:user)    { create(:user) }
  let(:setting) { ApplicationSetting.create_from_defaults }
  let(:service) { described_class.new(setting, user, opts) }

  describe '#execute' do
    context 'common params' do
      let(:opts) { { home_page_url: 'http://foo.bar' } }

      it 'properly updates settings with given params' do
        service.execute

        expect(setting.home_page_url).to eql(opts[:home_page_url])
      end
    end

    context 'with valid params' do
      let(:opts) { { repository_size_limit: '100' } }

      it 'returns success params' do
        expect(service.execute).to be(true)
      end
    end

    context 'with invalid params' do
      let(:opts) { { repository_size_limit: '-100' } }

      it 'returns error params' do
        expect(service.execute).to be(false)
      end
    end

    context 'repository_size_limit assignment as Bytes' do
      let(:service) { described_class.new(setting, user, opts) }

      context 'when param present' do
        let(:opts) { { repository_size_limit: '100' } }

        it 'converts from MB to Bytes' do
          service.execute

          expect(setting.reload.repository_size_limit).to eql(100 * 1024 * 1024)
        end
      end

      context 'when param not present' do
        let(:opts) { { repository_size_limit: '' } }

        it 'does not update due to invalidity' do
          service.execute

          expect(setting.reload.repository_size_limit).to be_zero
        end

        it 'assign nil value' do
          service.execute

          expect(setting.repository_size_limit).to be_nil
        end
      end
    end
  end

  context 'when external authorization is enabled' do
    before do
      enable_external_authorization_service_check
    end

    it 'does not save the settings with an error if the service denies access' do
      expect(EE::Gitlab::ExternalAuthorization)
        .to receive(:access_allowed?).with(user, 'new-label') { false }

      described_class.new(setting, user, { external_authorization_service_default_label: 'new-label' }).execute

      expect(setting.errors[:external_authorization_service_default_label]).to be_present
    end

    it 'saves the setting when the user has access to the label' do
      expect(EE::Gitlab::ExternalAuthorization)
        .to receive(:access_allowed?).with(user, 'new-label') { true }

      described_class.new(setting, user, { external_authorization_service_default_label: 'new-label' }).execute

      # Read the attribute directly to avoid the stub from
      # `enable_external_authorization_service_check`
      expect(setting[:external_authorization_service_default_label]).to eq('new-label')
    end

    it 'does not validate the label if it was not passed' do
      expect(EE::Gitlab::ExternalAuthorization)
        .not_to receive(:access_allowed?)

      described_class.new(setting, user, { home_page_url: 'http://foo.bar' }).execute
    end
  end
end
