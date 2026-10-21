# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::PolicyStore::Triggers do
  describe "::ALL" do
    it "enumerates the triggers a policy can target" do
      expect(described_class::ALL).to eq(
        [
          { id: 'deployment_requested', name: 'Deployment requested', kind: 'gate' },
          { id: 'environment_advanced', name: 'Environment advanced', kind: 'gate' },
          { id: 'deployment_promoted', name: 'Deployment promoted', kind: 'gate' },
          { id: 'project.before_settings_update', name: 'Project settings change requested', kind: 'gate' },
          { id: 'project.after_create', name: 'Project created', kind: 'event' },
          { id: 'project.after_transfer', name: 'Project transferred', kind: 'event' }
        ]
      )
    end

    it "catalogues only canonical types, so authoring cannot outrun the persisted vocabulary" do
      expect(described_class::ALL.map { |trigger| trigger[:id] } - described_class::TYPES).to be_empty
    end

    # The engine records the drift check on a schedule; offering it for authoring would
    # let a policy target a trigger no author can answer.
    it "omits the drift check, which is persisted-only" do
      expect(described_class::ALL.map { |trigger| trigger[:id] })
        .not_to include(described_class::PROJECT_SETTINGS_DRIFT_CHECKED)
    end

    it "is frozen down to each trigger, so no caller can mutate the catalogue" do
      expect(described_class::ALL).to be_frozen
      expect(described_class::ALL).to all(be_frozen)
    end
  end

  describe "::TYPES" do
    it "is frozen, so no caller can mutate the vocabulary" do
      expect(described_class::TYPES).to be_frozen
    end

    it "holds each id once, in the order of the Govern enums" do
      expect(described_class::TYPES).to eq(
        %w[
          deployment_requested environment_advanced deployment_promoted
          project.before_settings_update project.scheduled_settings_drift_check
          project.after_create project.after_transfer
        ]
      )
    end
  end
end
