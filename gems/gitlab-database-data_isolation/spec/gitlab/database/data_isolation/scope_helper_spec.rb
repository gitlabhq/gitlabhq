# frozen_string_literal: true

RSpec.describe Gitlab::Database::DataIsolation::ScopeHelper do
  describe ".without_data_isolation" do
    it "delegates to Context.without_data_isolation" do
      disabled_inside = nil

      described_class.without_data_isolation do
        disabled_inside = Gitlab::Database::DataIsolation::Context.disabled?
      end

      expect(disabled_inside).to be(true)
    end

    it "restores state after the block" do
      described_class.without_data_isolation { nil }

      expect(Gitlab::Database::DataIsolation::Context).not_to be_disabled
    end
  end
end
