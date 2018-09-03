# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Email::Handler do
  before do
    stub_incoming_email_setting(enabled: true, address: "incoming+%{key}@appmail.adventuretime.ooo")
    stub_config_setting(host: 'localhost')
  end

  describe '.for' do
    def handler_for(fixture, mail_key)
      described_class.for(fixture_file(fixture), mail_key)
    end

    def ee_handler_for(fixture, mail_key)
      described_class.for(fixture_file(fixture, dir: 'ee'), mail_key)
    end

    context 'a Service Desk email' do
      it 'uses the Service Desk handler when Service Desk is enabled' do
        allow(License).to receive(:feature_available?).and_call_original
        allow(License).to receive(:feature_available?).with(:service_desk).and_return(true)

        expect(ee_handler_for('emails/service_desk.eml', 'some/project')).to be_instance_of(Gitlab::Email::Handler::EE::ServiceDeskHandler)
      end

      it 'uses no handler when Service Desk is disabled' do
        allow(License).to receive(:feature_available?).and_call_original
        allow(License).to receive(:feature_available?).with(:service_desk).and_return(false)

        expect(ee_handler_for('emails/service_desk.eml', 'some/project')).to be_nil
      end
    end

    context 'a new issue email' do
      let!(:user) { create(:user, email: 'jake@adventuretime.ooo', incoming_email_token: 'auth_token') }

      it 'uses the create issue handler when Service Desk is enabled' do
        allow(License).to receive(:feature_available?).and_call_original
        allow(License).to receive(:feature_available?).with(:service_desk).and_return(true)

        expect(handler_for('emails/valid_new_issue.eml', 'some/project+auth_token')).to be_instance_of(Gitlab::Email::Handler::CreateIssueHandler)
      end

      it 'uses the create issue handler when Service Desk is disabled' do
        allow(License).to receive(:feature_available?).and_call_original
        allow(License).to receive(:feature_available?).with(:service_desk).and_return(false)

        expect(handler_for('emails/valid_new_issue.eml', 'some/project+auth_token')).to be_instance_of(Gitlab::Email::Handler::CreateIssueHandler)
      end
    end
  end
end
