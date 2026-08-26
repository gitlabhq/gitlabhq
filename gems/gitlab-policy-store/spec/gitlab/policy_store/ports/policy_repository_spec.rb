# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::PolicyStore::Ports::PolicyRepository do
  describe "MAX_COMPILED_RULES_BYTES" do
    # Every other example stubs this constant, so without one assertion on the value itself,
    # changing it leaves the suite green while doc/api/policy_store.md keeps promising 65536.
    it "holds the figure the API documentation promises callers" do
      expect(described_class::MAX_COMPILED_RULES_BYTES).to eq(65_536)
    end
  end
end
