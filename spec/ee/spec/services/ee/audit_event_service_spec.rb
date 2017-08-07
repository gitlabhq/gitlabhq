require 'spec_helper'

describe AuditEventService do
  describe '#for_failed_login' do
    let(:author_name) { 'testuser' }
    let(:ip_address) { '127.0.0.1' }
    let(:service) { described_class.new(author_name, nil, ip_address: ip_address) }
    let(:event) { service.for_failed_login.unauth_security_event }

    it 'has the right type' do
      expect(event.entity_type).to eq('User')
    end

    it 'has the right author' do
      expect(event.details[:author_name]).to eq(author_name)
    end

    it 'has the right IP address' do
      allow(service).to receive(:admin_audit_log_enabled?).and_return(true)

      expect(event.details[:ip_address]).to eq(ip_address)
    end

    it 'has the right auth method for OAUTH' do
      oauth_service = described_class.new(author_name, nil, ip_address: ip_address, with: 'ldap')
      event = oauth_service.for_failed_login.unauth_security_event

      expect(event.details[:failed_login]).to eq('LDAP')
    end
  end
end
