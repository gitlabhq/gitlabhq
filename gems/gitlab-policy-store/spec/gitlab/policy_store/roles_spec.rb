# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::PolicyStore::Roles do
  describe "::GITLAB_ROLES" do
    it "enumerates the GitLab project/group roles" do
      expect(described_class::GITLAB_ROLES).to eq(
        [
          { id: 'developer', name: 'Developer' },
          { id: 'maintainer', name: 'Maintainer' },
          { id: 'owner', name: 'Owner' }
        ]
      )
    end

    it "is frozen down to each role, so no caller can mutate the catalogue" do
      expect(described_class::GITLAB_ROLES).to be_frozen
      expect(described_class::GITLAB_ROLES).to all(be_frozen)
    end
  end

  describe "::CD_ROLES" do
    it "enumerates the CD-specific roles" do
      expect(described_class::CD_ROLES).to eq(
        [
          { id: 'deployment_observer', name: 'Deployment Observer' },
          { id: 'release_manager', name: 'Release Manager' }
        ]
      )
    end

    it "is frozen down to each role, so no caller can mutate the catalogue" do
      expect(described_class::CD_ROLES).to be_frozen
      expect(described_class::CD_ROLES).to all(be_frozen)
    end
  end

  describe "::DEPLOYMENT_TRIGGERS" do
    it "includes all deployment trigger types" do
      expect(described_class::DEPLOYMENT_TRIGGERS).to eq(
        %w[deployment_requested environment_advanced deployment_promoted]
      )
    end

    it "is a subset of Triggers::TYPES" do
      expect(described_class::DEPLOYMENT_TRIGGERS - Gitlab::PolicyStore::Triggers::TYPES).to be_empty
    end
  end

  describe ".for_trigger" do
    context "with a deployment trigger" do
      it "returns only CD roles" do
        %w[deployment_requested environment_advanced deployment_promoted].each do |trigger|
          roles = described_class.for_trigger(trigger)

          expect(roles).to eq(described_class::CD_ROLES)
          expect(roles).not_to include(*described_class::GITLAB_ROLES)
          expect(roles.size).to eq(2)
        end
      end
    end

    context "with a non-deployment trigger" do
      it "returns only GitLab roles" do
        roles = described_class.for_trigger('some_other_trigger')

        expect(roles).to eq(described_class::GITLAB_ROLES)
        expect(roles).not_to include(*described_class::CD_ROLES)
      end
    end

    context "with nil trigger" do
      it "returns only GitLab roles" do
        roles = described_class.for_trigger(nil)

        expect(roles).to eq(described_class::GITLAB_ROLES)
      end
    end
  end

  describe ".gitlab_role_ids" do
    it "returns the IDs of GitLab roles" do
      expect(described_class.gitlab_role_ids).to eq(%w[developer maintainer owner])
    end

    it "returns the same object on repeated calls to avoid allocations" do
      first_call = described_class.gitlab_role_ids
      second_call = described_class.gitlab_role_ids
      expect(first_call).to be(second_call)
    end
  end

  describe ".cd_role_ids" do
    it "returns the IDs of CD roles" do
      expect(described_class.cd_role_ids).to eq(%w[deployment_observer release_manager])
    end

    it "returns the same object on repeated calls to avoid allocations" do
      first_call = described_class.cd_role_ids
      second_call = described_class.cd_role_ids
      expect(first_call).to be(second_call)
    end
  end

  describe ".all_role_ids" do
    it "returns the IDs of all roles" do
      expect(described_class.all_role_ids).to eq(
        %w[developer maintainer owner deployment_observer release_manager]
      )
    end

    it "returns the same object on repeated calls to avoid allocations" do
      first_call = described_class.all_role_ids
      second_call = described_class.all_role_ids
      expect(first_call).to be(second_call)
    end
  end
end
