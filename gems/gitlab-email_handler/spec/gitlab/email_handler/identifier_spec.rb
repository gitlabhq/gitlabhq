# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::EmailHandler::Identifier, feature_category: :service_desk do
  describe '.call' do
    subject(:identification) { described_class.call(mail_key) }

    let(:target_class) { Gitlab::EmailHandler::Target }

    context 'with a partitioned reply key that encodes a namespace id' do
      # partition "rs" (1000 base36), 25-char reply key, namespace "rs" (1000)
      let(:mail_key) { 'rs-0000000000000000000000abc-rs' }

      it 'identifies the target by the decoded namespace id' do
        expect(identification.handler).to eq(:create_note)
        expect(identification.decoded_namespace_id).to eq(1000)
        expect(identification.target).to eq(target_class.namespace_id(1000))
      end
    end

    context 'with a partitioned reply key without a namespace id' do
      let(:mail_key) { 'rs-0000000000000000000000abc' }

      it 'matches create_note but cannot be self-identified' do
        expect(identification.handler).to eq(:create_note)
        expect(identification.decoded_namespace_id).to be_nil
        expect(identification.target).to be_nil
      end
    end

    context 'with a legacy hex reply key' do
      let(:mail_key) { '59d8df8370b7e95c5a49fbf86aeb2c93' }

      it 'matches create_note but cannot be self-identified' do
        expect(identification.handler).to eq(:create_note)
        expect(identification.target).to be_nil
      end
    end

    context 'with an issue creation key' do
      let(:mail_key) { 'gitlab-org-gitlab-ce-20-Author_Token12345678-issue' }

      it 'identifies the target by project id' do
        expect(identification.handler).to eq(:create_issue)
        expect(identification.target).to eq(target_class.project_id(20))
      end
    end

    context 'with a legacy issue creation key' do
      let(:mail_key) { 'gitlab-org/gitlab-ce+Author_Token12345678' }

      it 'identifies the target by the full project path as a route' do
        expect(identification.handler).to eq(:create_issue)
        # gitlab-org is the top-level segment of gitlab-org/gitlab-ce
        expect(identification.target).to eq(target_class.route("gitlab-org"))
      end
    end

    context 'with a note-on-issuable key' do
      let(:mail_key) { 'gitlab-org-gitlab-ce-20-Author_Token12345678-issue-34' }

      it 'identifies the target by project id' do
        expect(identification.handler).to eq(:create_note_on_issuable)
        expect(identification.target).to eq(target_class.project_id(20))
      end
    end

    context 'with a merge request creation key' do
      let(:mail_key) { 'gitlab-org-gitlab-ce-20-Author_Token12345678-merge-request' }

      it 'identifies the target by project id' do
        expect(identification.handler).to eq(:create_merge_request)
        expect(identification.target).to eq(target_class.project_id(20))
      end
    end

    context 'with a service desk issue key' do
      let(:mail_key) { 'gitlab-org-gitlab-ce-20-issue-' }

      it 'identifies the target by project id' do
        expect(identification.handler).to eq(:service_desk)
        expect(identification.target).to eq(target_class.project_id(20))
      end
    end

    context 'with a legacy service desk key' do
      let(:mail_key) { 'gitlab-org/gitlab-ce' }

      it 'identifies the target by the full project path as a route' do
        expect(identification.handler).to eq(:service_desk)
        # gitlab-org is the top-level segment of gitlab-org/gitlab-ce
        expect(identification.target).to eq(target_class.route("gitlab-org"))
      end
    end

    context 'with an unknown key' do
      let(:mail_key) { '!!!not-a-key!!!' }

      it { is_expected.to be_nil }
    end

    context 'with a nil key' do
      let(:mail_key) { nil }

      it { is_expected.to be_nil }
    end

    context 'with a legacy issue key whose token contains a "+"' do
      let(:mail_key) { 'gitlab-org/gitlab-ce+Author_Token+extra' }

      it 'is not identified at all' do
        expect(identification).to be_nil
      end
    end

    context 'with a legacy unsubscribe key' do
      let(:mail_key) { '59d8df8370b7e95c5a49fbf86aeb2c93+unsubscribe' }

      it 'is identified as unsubscribe, not create_issue' do
        expect(identification.handler).to eq(:unsubscribe)
      end
    end
  end

  describe '.for_handler' do
    it 'returns the identification only when the key matches the requested handler' do
      key = 'gitlab-org-gitlab-ce-20-Author_Token12345678-issue'

      expect(described_class.for_handler(:create_issue, key).handler).to eq(:create_issue)
    end

    it 'returns nil when the key does not match the requested handler' do
      key = 'gitlab-org-gitlab-ce-20-Author_Token12345678-issue'

      expect(described_class.for_handler(:create_merge_request, key)).to be_nil
    end

    it 'returns nil for an unknown handler name' do
      expect(described_class.for_handler(:nonexistent, 'anything')).to be_nil
    end
  end
end
