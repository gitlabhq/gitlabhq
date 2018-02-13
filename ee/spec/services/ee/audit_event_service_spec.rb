require 'spec_helper'

describe AuditEventService do
  describe '#for_failed_login' do
    let(:author_name) { 'testuser' }
    let(:ip_address) { '127.0.0.1' }
    let(:service) { described_class.new(author_name, nil, ip_address: ip_address) }
    let(:event) { service.for_failed_login.unauth_security_event }

    before do
      stub_licensed_features(extended_audit_events: true)
    end

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

  describe 'license' do
    let(:project) { create(:project) }
    let(:user) { create(:user) }
    let!(:service) { described_class.new(user, project, action: :create) }
    let(:event) { service.for_project.security_event }

    before do
      disable_license_audit_features(service)
    end

    describe 'has the audit_admin feature' do
      before do
        allow(service).to receive(:admin_audit_log_enabled?).and_return(true)
      end

      it 'logs an audit event' do
        expect { event }.to change(AuditEvent, :count).by(1)
      end

      it 'has the entity_path' do
        expect(event.details[:entity_path]).to eq(project.full_path)
      end
    end

    describe 'has the extended_audit_events feature' do
      before do
        allow(service).to receive(:entity_audit_events_enabled?).and_return(true)
      end

      it 'logs an audit event' do
        expect { event }.to change(AuditEvent, :count).by(1)
      end

      it 'has not the entity_path' do
        expect(event.details[:entity_path]).not_to eq(project.full_path)
      end
    end

    describe 'entity has the audit_events feature' do
      before do
        allow(service).to receive(:audit_events_enabled?).and_return(true)
      end

      it 'logs an audit event' do
        expect { event }.to change(AuditEvent, :count).by(1)
      end

      it 'has not the entity_path' do
        expect(event.details[:entity_path]).not_to eq(project.full_path)
      end
    end

    describe 'has not any audit event feature' do
      it 'does not log the audit event' do
        expect { event }.not_to change(AuditEvent, :count)
      end
    end

    def disable_license_audit_features(service)
      [:entity_audit_events_enabled?,
       :admin_audit_log_enabled?,
       :audit_events_enabled?].each do |f|
        allow(service).to receive(f).and_return(false)
      end
    end
  end
end
