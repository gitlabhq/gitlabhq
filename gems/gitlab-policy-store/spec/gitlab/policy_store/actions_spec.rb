# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::PolicyStore::Actions do
  describe "::ALL" do
    it "enumerates the actions a policy can take" do
      expect(described_class::ALL).to eq(
        [
          { id: 'block', name: 'Block' },
          { id: 'require_approval', name: 'Require approval' }
        ]
      )
    end

    it "is frozen down to each action, so no caller can mutate the catalogue" do
      expect(described_class::ALL).to be_frozen
      expect(described_class::ALL).to all(be_frozen)
    end
  end
end
