require 'spec_helper'

describe Geo::LfsObjectRegistryFinder, :geo do
  include ::EE::GeoHelpers

  let(:secondary) { create(:geo_node) }
  let(:synced_group) { create(:group) }
  let(:synced_project) { create(:project, group: synced_group) }
  let(:unsynced_project) { create(:project) }
  let(:lfs_object_1) { create(:lfs_object) }
  let(:lfs_object_2) { create(:lfs_object) }
  let(:lfs_object_3) { create(:lfs_object) }

  subject { described_class.new(current_node: secondary) }

  before do
    stub_current_geo_node(secondary)
  end

  describe '#count_synced_lfs_objects' do
    it 'delegates to #find_synced_lfs_objects_registries' do
      expect(subject).to receive(:find_synced_lfs_objects_registries).and_call_original

      subject.count_synced_lfs_objects
    end

    it 'counts LFS objects that has been synced' do
      create(:geo_file_registry, :lfs, file_id: lfs_object_1.id, success: false)
      create(:geo_file_registry, :lfs, file_id: lfs_object_2.id)
      create(:geo_file_registry, :lfs, file_id: lfs_object_3.id)

      expect(subject.count_synced_lfs_objects).to eq 2
    end

    context 'with selective sync' do
      before do
        secondary.update_attribute(:namespaces, [synced_group])
      end

      it 'delegates to #legacy_find_synced_lfs_objects' do
        expect(subject).to receive(:legacy_find_synced_lfs_objects).and_call_original

        subject.count_synced_lfs_objects
      end

      it 'counts LFS objects that has been synced' do
        allow_any_instance_of(LfsObjectsProject).to receive(:update_project_statistics).and_return(nil)

        create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_1)
        create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_2)
        create(:lfs_objects_project, project: unsynced_project, lfs_object: lfs_object_3)

        create(:geo_file_registry, :lfs, file_id: lfs_object_1.id, success: false)
        create(:geo_file_registry, :lfs, file_id: lfs_object_2.id)
        create(:geo_file_registry, :lfs, file_id: lfs_object_3.id)

        expect(subject.count_synced_lfs_objects).to eq 1
      end
    end
  end

  describe '#count_failed_lfs_objects' do
    it 'delegates to #find_failed_lfs_objects_registries' do
      expect(subject).to receive(:find_failed_lfs_objects_registries).and_call_original

      subject.count_failed_lfs_objects
    end

    it 'counts LFS objects that sync has failed' do
      create(:geo_file_registry, :lfs, file_id: lfs_object_1.id, success: false)
      create(:geo_file_registry, :lfs, file_id: lfs_object_2.id)
      create(:geo_file_registry, :lfs, file_id: lfs_object_3.id, success: false)

      expect(subject.count_failed_lfs_objects).to eq 2
    end

    context 'with selective sync' do
      before do
        secondary.update_attribute(:namespaces, [synced_group])
      end

      it 'delegates to #legacy_find_failed_lfs_objects' do
        expect(subject).to receive(:legacy_find_failed_lfs_objects).and_call_original

        subject.count_failed_lfs_objects
      end

      it 'counts LFS objects that sync has failed' do
        allow_any_instance_of(LfsObjectsProject).to receive(:update_project_statistics).and_return(nil)

        create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_1)
        create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_2)
        create(:lfs_objects_project, project: unsynced_project, lfs_object: lfs_object_3)

        create(:geo_file_registry, :lfs, file_id: lfs_object_1.id, success: false)
        create(:geo_file_registry, :lfs, file_id: lfs_object_2.id)
        create(:geo_file_registry, :lfs, file_id: lfs_object_3.id, success: false)

        expect(subject.count_failed_lfs_objects).to eq 1
      end
    end
  end
end
