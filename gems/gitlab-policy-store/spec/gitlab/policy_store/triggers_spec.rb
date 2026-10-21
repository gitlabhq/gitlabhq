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

    it "catalogues only canonical types, so authoring cannot outrun the persisted vocabulary" do
      expect(described_class::ALL.map { |trigger| trigger[:id] } - described_class::TYPES).to be_empty
    end
  end

  describe "::TYPES" do
    it "holds each id once, in the order of the Govern enums" do
      expect(described_class::TYPES).to eq(
        %w[
          deployment_requested environment_advanced deployment_promoted
          project.before_settings_update project.scheduled_settings_drift_check
          project.after_create project.after_transfer
        ]
      )
    end

    it "is frozen down to each trigger, so no caller can mutate the catalogue" do
      expect(described_class::ALL).to be_frozen
      expect(described_class::ALL).to all(be_frozen)
    end
  end
end
