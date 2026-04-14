# frozen_string_literal: true

RSpec.describe Gitlab::Database::DataIsolation::Context do
  after do
    described_class.enable!
  end

  describe ".disable! / .enable! / .disabled?" do
    it "is not disabled by default" do
      expect(described_class).not_to be_disabled
    end

    it "can be disabled" do
      described_class.disable!

      expect(described_class).to be_disabled
    end

    it "can be re-enabled" do
      described_class.disable!
      described_class.enable!

      expect(described_class).not_to be_disabled
    end
  end

  describe ".without_data_isolation" do
    it "disables scoping within the block" do
      disabled_inside = nil

      described_class.without_data_isolation do
        disabled_inside = described_class.disabled?
      end

      expect(disabled_inside).to be(true)
    end

    it "restores the previous state after the block" do
      described_class.without_data_isolation { nil }

      expect(described_class).not_to be_disabled
    end

    it "restores the previous state even on exception" do
      begin
        described_class.without_data_isolation { raise "boom" }
      rescue RuntimeError
        nil
      end

      expect(described_class).not_to be_disabled
    end

    it "preserves already-disabled state" do
      described_class.disable!

      described_class.without_data_isolation { nil }

      expect(described_class).to be_disabled
    end
  end
end
