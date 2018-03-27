require 'spec_helper'

describe EventsHelper do
  describe '#event_commit_title' do
    let(:message) { "foo & bar " + "A" * 70 + "\n" + "B" * 80 }
    subject { helper.event_commit_title(message) }

    it "returns the first line, truncated to 70 chars" do
      is_expected.to eq(message[0..66] + "...")
    end

    it "is not html-safe" do
      is_expected.not_to be_a(ActiveSupport::SafeBuffer)
    end

    it "handles empty strings" do
      expect(helper.event_commit_title("")).to eq("")
    end

    it 'handles nil values' do
      expect(helper.event_commit_title(nil)).to eq('')
    end

    it 'does not escape HTML entities' do
      expect(helper.event_commit_title("foo & bar")).to eq("foo & bar")
    end
  end
end
