# frozen_string_literal: true

require 'spec_helper'
require 'mail'

RSpec.describe Gitlab::EmailHandler::MailKey, feature_category: :service_desk do
  let(:wildcard_address) { 'incoming+%{key}@example.com' }
  let(:gitlab_host) { 'gitlab.example.com' }

  def mail(raw)
    Mail::Message.new(raw)
  end

  # Resolves the first candidate key, mirroring how Gitlab::Email::Receiver and
  # the mail_room service consume each_candidate.
  def first_key(raw)
    described_class.each_candidate(mail(raw), wildcard_address: wildcard_address, gitlab_host: gitlab_host, &:key)
  end

  describe '.each_candidate' do
    it 'returns nil without a block' do
      expect(described_class.each_candidate(mail("To: x@y.com\n\nbody"), wildcard_address: wildcard_address,
        gitlab_host: gitlab_host)).to be_nil
    end

    context 'with a key in a recipient header' do
      it 'finds the key in the To header' do
        expect(first_key("To: incoming+abc@example.com\n\nbody")).to eq('abc')
      end

      it 'finds the key in the Delivered-To header' do
        expect(first_key("To: jake@example.com\nDelivered-To: incoming+def@example.com\n\nbody")).to eq('def')
      end

      it 'finds the key in the Cc header' do
        expect(first_key("To: jake@example.com\nCc: incoming+ghi@example.com\n\nbody")).to eq('ghi')
      end

      it 'strips angle brackets around the address' do
        expect(first_key("To: jake@example.com\nEnvelope-To: <incoming+jkl@example.com>\n\nbody")).to eq('jkl')
      end

      it 'extracts the recipient from a Received header' do
        raw = "To: jake@example.com\nReceived: from x by y for <incoming+mno@example.com>; date\n\nbody"
        expect(first_key(raw)).to eq('mno')
      end
    end

    context 'with a references message-id fallback' do
      it 'finds the key from a reply message id' do
        raw = "To: jake@example.com\nReferences: <a@example.com> <reply-pqr@gitlab.example.com>\n\nbody"
        expect(first_key(raw)).to eq('pqr')
      end

      it 'ignores message ids for a different host' do
        raw = "To: jake@example.com\nReferences: <a@example.com> <reply-pqr@other.example.com>\n\nbody"
        expect(first_key(raw)).to be_nil
      end
    end

    describe 'precedence' do
      it 'prefers the To header over other recipient headers' do
        raw = "To: incoming+fromto@example.com\nDelivered-To: incoming+fromdt@example.com\n\nbody"
        expect(first_key(raw)).to eq('fromto')
      end

      it 'prefers the references fallback over the additional headers' do
        raw = <<~EMAIL
          To: jake@example.com
          Delivered-To: incoming+fromdt@example.com
          References: <other@example.com> <reply-fromref@gitlab.example.com>

          body
        EMAIL
        expect(first_key(raw)).to eq('fromref')
      end
    end

    describe 'short-circuiting' do
      it 'returns the first non-nil block result and stops iterating' do
        seen = []
        result = described_class.each_candidate(
          mail("To: incoming+first@example.com\nCc: incoming+second@example.com\n\nbody"),
          wildcard_address: wildcard_address,
          gitlab_host: gitlab_host
        ) do |candidate|
          seen << candidate.value
          candidate.key
        end

        expect(result).to eq('first')
        expect(seen).to eq(['incoming+first@example.com'])
      end

      it 'yields the source, value and offline key for each candidate' do
        candidate = nil
        described_class.each_candidate(
          mail("To: support@acme.com\n\nbody"),
          wildcard_address: wildcard_address,
          gitlab_host: gitlab_host
        ) do |c|
          candidate = c
          nil
        end

        expect(candidate.source).to eq(:to)
        expect(candidate.value).to eq('support@acme.com')
        expect(candidate.key).to be_nil
      end

      it 'lets the block override the offline key (e.g. database-backed lookups)' do
        raw = "To: support@acme.com\n\nbody"
        result = described_class.each_candidate(mail(raw), wildcard_address: wildcard_address,
          gitlab_host: gitlab_host) do |candidate|
          'db-resolved-key' if candidate.source == :to
        end

        expect(result).to eq('db-resolved-key')
      end
    end

    it 'returns nil when no candidate matches' do
      expect(first_key("To: jake@example.com\n\nbody")).to be_nil
    end
  end

  describe '.key_from_address' do
    it 'parses the key from a wildcard address' do
      expect(described_class.key_from_address('incoming+abc@example.com', wildcard_address)).to eq('abc')
    end

    it 'returns nil for a non-matching address' do
      expect(described_class.key_from_address('someone@example.com', wildcard_address)).to be_nil
    end

    it 'returns nil without a wildcard address' do
      expect(described_class.key_from_address('incoming+abc@example.com', nil)).to be_nil
    end
  end

  describe '.key_from_fallback_message_id' do
    it 'parses the key from a reply message id' do
      expect(described_class.key_from_fallback_message_id('reply-abc@gitlab.example.com', gitlab_host)).to eq('abc')
    end

    it 'returns nil for a different host' do
      expect(described_class.key_from_fallback_message_id('reply-abc@other.com', gitlab_host)).to be_nil
    end

    it 'returns nil without a host' do
      expect(described_class.key_from_fallback_message_id('reply-abc@gitlab.example.com', nil)).to be_nil
    end
  end

  describe '.scan_fallback_references' do
    it 'splits comma and bracket joined references' do
      expect(described_class.scan_fallback_references('<a@example.com>,<b@example.com>'))
        .to eq(['a@example.com', 'b@example.com'])
    end

    it 'returns an empty array for blank input' do
      expect(described_class.scan_fallback_references(nil)).to eq([])
    end
  end
end
