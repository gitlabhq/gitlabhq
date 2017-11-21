require 'spec_helper'

describe RemoveUnreferencedLfsObjectsWorker do
  describe '#perform' do
    context 'when running in a Geo primary node' do
      set(:primary) { create(:geo_node, :primary) }
      set(:secondary) { create(:geo_node) }

      it 'logs an event to the Geo event log for every unreferenced LFS objects' do
        unreferenced_lfs_object_1 = create(:lfs_object, :with_file)
        unreferenced_lfs_object_2 = create(:lfs_object, :with_file)
        referenced_lfs_object = create(:lfs_object)
        create(:lfs_objects_project, lfs_object: referenced_lfs_object)

        expect { subject.perform }.to change(Geo::LfsObjectDeletedEvent, :count).by(2)
        expect(Geo::LfsObjectDeletedEvent.where(lfs_object: unreferenced_lfs_object_1.id)).to exist
        expect(Geo::LfsObjectDeletedEvent.where(lfs_object: unreferenced_lfs_object_2.id)).to exist
        expect(Geo::LfsObjectDeletedEvent.where(lfs_object: referenced_lfs_object.id)).not_to exist
      end
    end
  end
end
