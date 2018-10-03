# frozen_string_literal: true

require 'spec_helper'

describe Geo::LfsObjectDeletedEventStore do
  include EE::GeoHelpers

  set(:secondary_node) { create(:geo_node) }

  let(:lfs_object) { create(:lfs_object, :with_file, oid: 'b68143e6463773b1b6c6fd009a76c32aeec041faff32ba2ed42fd7f708a00004') }

  subject { described_class.new(lfs_object) }

  describe '#create!' do
    it_behaves_like 'a Geo event store', Geo::LfsObjectDeletedEvent do
      let(:file_subject) { lfs_object }
    end

    context 'when running on a primary node' do
      before do
        stub_primary_node
      end

      it 'tracks LFS object attributes' do
        subject.create!

        expect(Geo::LfsObjectDeletedEvent.last).to have_attributes(
          lfs_object_id: lfs_object.id,
          oid: lfs_object.oid,
          file_path: 'b6/81/43e6463773b1b6c6fd009a76c32aeec041faff32ba2ed42fd7f708a00004'
        )
      end

      it 'logs an error message when event creation fail' do
        invalid_lfs_object = create(:lfs_object)
        subject = described_class.new(invalid_lfs_object)

        expected_message = {
          class: "Geo::LfsObjectDeletedEventStore",
          lfs_object_id: invalid_lfs_object.id,
          file_path: nil,
          message: "Lfs object deleted event could not be created",
          error: "Validation failed: File path can't be blank"
        }

        expect(Gitlab::Geo::Logger).to receive(:error)
          .with(expected_message).and_call_original

        subject.create!
      end
    end
  end
end
