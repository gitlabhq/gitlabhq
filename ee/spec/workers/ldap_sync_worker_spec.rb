require 'spec_helper'

describe LdapSyncWorker do
  let(:subject) { described_class.new }

  before do
    allow(Sidekiq.logger).to receive(:info)
    allow(Gitlab::Auth::LDAP::Config).to receive(:enabled?).and_return(true)

    create(:omniauth_user, provider: 'ldapmain')
  end

  describe '#perform' do
    context 'with the default license key' do
      it 'syncs all LDAP users' do
        expect(Gitlab::Auth::LDAP::Access).to receive(:allowed?)

        subject.perform
      end
    end

    context 'without a license key' do
      before do
        License.destroy_all # rubocop: disable DestroyAll
      end

      it 'does not sync LDAP users' do
        expect(Gitlab::Auth::LDAP::Access).not_to receive(:allowed?)

        subject.perform
      end
    end
  end
end
