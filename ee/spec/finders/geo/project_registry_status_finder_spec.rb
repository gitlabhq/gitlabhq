# frozen_string_literal: true
require 'spec_helper'

describe Geo::ProjectRegistryStatusFinder, :geo do
  include ::EE::GeoHelpers

  set(:secondary) { create(:geo_node) }

  set(:synced_registry) { create(:geo_project_registry, :synced) }
  set(:synced_and_verified_registry) { create(:geo_project_registry, :synced, :repository_verified) }
  set(:sync_pending_registry) { create(:geo_project_registry, :synced, :repository_dirty) }
  set(:sync_failed_registry) { create(:geo_project_registry, :existing_repository_sync_failed) }

  set(:verify_outdated_registry) { create(:geo_project_registry, :synced, :repository_verification_outdated) }
  set(:verify_failed_registry) { create(:geo_project_registry, :synced, :repository_verification_failed) }
  set(:verify_checksum_mismatch_registry) { create(:geo_project_registry, :synced, :repository_checksum_mismatch) }

  set(:never_synced_registry) { create(:geo_project_registry) }
  set(:never_synced_registry_with_failure) { create(:geo_project_registry, :repository_sync_failed) }
  set(:project_without_registry) { create(:project, name: 'project without registry') }
  let(:project_with_never_synced_registry) { never_synced_registry.project }

  subject { described_class.new(current_node: secondary) }

  before do
    skip('FDW is not configured') if Gitlab::Database.postgresql? && !Gitlab::Geo::Fdw.enabled?
    stub_current_geo_node(secondary)
  end

  describe '#synced_projects' do
    it 'returns only synced registry' do
      result = subject.synced_projects

      expect(result).to contain_exactly(synced_and_verified_registry)
    end
  end

  describe '#pending_projects' do
    it 'returns only pending registry' do
      result = subject.pending_projects

      expect(result).to contain_exactly(
        synced_registry,
        sync_pending_registry,
        verify_outdated_registry
      )
    end
  end

  describe '#failed_projects' do
    it 'returns only failed registry' do
      result = subject.failed_projects

      expect(result).to contain_exactly(
        sync_failed_registry,
        never_synced_registry_with_failure,
        verify_failed_registry,
        verify_checksum_mismatch_registry
      )
    end
  end

  describe '#never_synced_projects' do
    it 'returns only FDW projects without registry or with never synced registries' do
      fdw_project_with_never_synced_registry_with_failure = Geo::Fdw::Project.find(never_synced_registry_with_failure.project.id)
      fdw_project_with_never_synced_registry = Geo::Fdw::Project.find(project_with_never_synced_registry.id)
      fdw_project_without_registry = Geo::Fdw::Project.find(project_without_registry.id)

      result = subject.never_synced_projects

      expect(result).to contain_exactly(
        fdw_project_without_registry,
        fdw_project_with_never_synced_registry,
        fdw_project_with_never_synced_registry_with_failure
      )
    end
  end
end
