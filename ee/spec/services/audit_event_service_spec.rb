require 'spec_helper'

describe AuditEventService do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:project_member) { create(:project_member, user: user) }
  let(:service) { described_class.new(user, project, { action: :destroy }) }

  describe '#for_member' do
    it 'generates event' do
      event = service.for_member(project_member).security_event
      expect(event[:details][:target_details]).to eq(user.name)
    end

    it 'handles deleted users' do
      expect(project_member).to receive(:user).and_return(nil)

      event = service.for_member(project_member).security_event
      expect(event[:details][:target_details]).to eq('Deleted User')
    end

    it 'has the IP address' do
      event = service.for_member(project_member).security_event
      expect(event[:details][:ip_address]).to eq(user.current_sign_in_ip)
    end

    context 'admin audit log licensed' do
      before do
        stub_licensed_features(admin_audit_log: true)
      end

      it 'has the entity full path' do
        event = service.for_member(project_member).security_event
        expect(event[:details][:entity_path]).to eq(project.full_path)
      end
    end
  end

  describe '#security_event' do
    context 'unlicensed' do
      before do
        stub_licensed_features(audit_events: false)
      end

      it 'does not create an event' do
        expect(SecurityEvent).not_to receive(:create)

        service.security_event
      end
    end

    context 'licensed' do
      it 'creates an event' do
        expect { service.security_event }.to change(SecurityEvent, :count).by(1)
      end
    end
  end

  describe '#entity_audit_events_enabled??' do
    context 'entity is a project' do
      let(:service) { described_class.new(user, project, { action: :destroy }) }

      it 'returns false when project is unlicensed' do
        stub_licensed_features(audit_events: false)

        expect(service.entity_audit_events_enabled?).to be_falsy
      end

      it 'returns true when project is licensed' do
        stub_licensed_features(audit_events: true)

        expect(service.entity_audit_events_enabled?).to be_truthy
      end
    end

    context 'entity is a group' do
      let(:group) { create(:group) }
      let(:service) { described_class.new(user, group, { action: :destroy }) }

      it 'returns false when group is unlicensed' do
        stub_licensed_features(audit_events: false)

        expect(service.entity_audit_events_enabled?).to be_falsy
      end

      it 'returns true when group is licensed' do
        stub_licensed_features(audit_events: true)

        expect(service.entity_audit_events_enabled?).to be_truthy
      end
    end

    context 'entity is a user' do
      let(:service) { described_class.new(user, user, { action: :destroy }) }

      it 'returns false when unlicensed' do
        stub_licensed_features(audit_events: false, admin_audit_log: false)

        expect(service.audit_events_enabled?).to be_falsey
      end

      it 'returns true when licensed with extended events' do
        stub_licensed_features(extended_audit_events: true)

        expect(service.audit_events_enabled?).to be_truthy
      end
    end

    context 'auth event' do
      let(:service) { described_class.new(user, user, { with: 'auth' }) }

      it 'returns true when unlicensed' do
        stub_licensed_features(audit_events: false, admin_audit_log: false)

        expect(service.audit_events_enabled?).to be_truthy
      end
    end
  end

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
