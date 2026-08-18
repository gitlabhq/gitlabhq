# frozen_string_literal: true

require 'spec_helper'
require 'cells/mailroom/recipient_targets'

RSpec.describe Cells::Mailroom::RecipientTargets do
  let(:target) { Gitlab::EmailHandler::Target }

  def candidate(value:, key: nil, source: :to)
    Gitlab::EmailHandler::MailKey::Candidate.new(source: source, value: value, key: key)
  end

  describe '.for_candidate' do
    it 'derives a project id target from a wildcard key' do
      result = described_class.for_candidate(
        candidate(value: 'incoming+gitlab-org-gitlab-ce-20-Author_Token12345678-issue@example.com',
          key: 'gitlab-org-gitlab-ce-20-Author_Token12345678-issue')
      )

      expect(result.first).to eq(target.project_id(20))
    end

    it 'derives a route target from a legacy wildcard key' do
      result = described_class.for_candidate(
        candidate(value: 'incoming+gitlab-org/gitlab-ce+Author_Token12345678@example.com',
          key: 'gitlab-org/gitlab-ce+Author_Token12345678')
      )

      expect(result.first).to eq(target.route('gitlab-org'))
    end

    it 'derives a custom email target from a bare address' do
      result = described_class.for_candidate(candidate(value: 'support@acme.com'))

      expect(result).to eq([target.service_desk_custom_email('support@acme.com')])
    end

    it 'derives a project key address slug target from an opaque service desk key' do
      result = described_class.for_candidate(
        candidate(value: 'contact+gitlab-org-gitlab-ce-mykey_123@example.com',
          key: 'gitlab-org-gitlab-ce-mykey_123')
      )

      expect(result.first).to eq(target.service_desk_project_key_address_slug('gitlab-org-gitlab-ce-mykey_123'))
    end

    it 'derives a namespace id target from a custom email reply key' do
      result = described_class.for_candidate(
        candidate(value: 'support+rs-0000000000000000000000abc-rs@acme.com')
      )

      expect(result).to include(target.namespace_id(1000))
    end

    it 'orders the wildcard key target before the custom email fallback' do
      result = described_class.for_candidate(
        candidate(value: 'incoming+gitlab-org-gitlab-ce-20-Author_Token12345678-issue@example.com',
          key: 'gitlab-org-gitlab-ce-20-Author_Token12345678-issue')
      )

      expect(result.first).to eq(target.project_id(20))
    end

    it 'returns no targets for an address that is not email-shaped and has no key' do
      expect(described_class.for_candidate(candidate(value: 'not-an-email'))).to be_empty
    end

    it 'de-duplicates identical targets' do
      result = described_class.for_candidate(
        candidate(value: 'incoming+gitlab-org-gitlab-ce-20-Author_Token12345678-issue@example.com',
          key: 'gitlab-org-gitlab-ce-20-Author_Token12345678-issue')
      )

      expect(result.count(target.project_id(20))).to eq(1)
    end
  end
end
