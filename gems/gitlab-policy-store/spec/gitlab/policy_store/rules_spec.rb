# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::PolicyStore::Rules do
  describe "::ALL" do
    it "enumerates the rule kinds a policy can be built from" do
      expect(described_class::ALL).to eq(
        [
          { id: 'custom', name: 'Custom' },
          { id: 'calendar', name: 'Calendar' },
          { id: 'environment', name: 'Environment' }
        ]
      )
    end

    it "is frozen down to each rule, so no caller can mutate the catalogue" do
      expect(described_class::ALL).to be_frozen
      expect(described_class::ALL).to all(be_frozen)
    end
  end
end
