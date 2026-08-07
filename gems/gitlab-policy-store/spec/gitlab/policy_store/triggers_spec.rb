# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::PolicyStore::Triggers do
  describe "::ALL" do
    it "enumerates the triggers a policy can target" do
      expect(described_class::ALL).to eq(
        [
          { id: 'deployment_requested', name: 'Deployment' }
        ]
      )
    end

    it "is frozen down to each trigger, so no caller can mutate the catalogue" do
      expect(described_class::ALL).to be_frozen
      expect(described_class::ALL).to all(be_frozen)
    end
  end
end
