# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::PolicyStore::Triggers do
  describe "::ALL" do
    it "enumerates the triggers a policy can target" do
      expect(described_class::ALL).to eq(
        [
          { id: 'deployment_requested', name: 'Deployment requested' },
          { id: 'environment_advanced', name: 'Environment advanced' },
          { id: 'deployment_promoted', name: 'Deployment promoted' }
        ]
      )
    end

    it "catalogues exactly the canonical types, so the catalogue can neither drift ahead nor lag behind" do
      expect(described_class::ALL.map { |trigger| trigger[:id] }).to eq(described_class::TYPES)
    end

    it "is frozen down to each trigger, so no caller can mutate the catalogue" do
      expect(described_class::ALL).to be_frozen
      expect(described_class::ALL).to all(be_frozen)
    end
  end
end
