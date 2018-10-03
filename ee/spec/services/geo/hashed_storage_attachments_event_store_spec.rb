# frozen_string_literal: true

require 'spec_helper'

describe Geo::HashedStorageAttachmentsEventStore do
  include EE::GeoHelpers

  set(:secondary_node) { create(:geo_node) }

  let(:project) { create(:project, path: 'bar') }
  let(:attachments_event) { build(:geo_hashed_storage_attachments_event, project: project) }
  let(:old_attachments_path) { attachments_event.old_attachments_path }
  let(:new_attachments_path) {attachments_event.new_attachments_path }

  subject { described_class.new(project, old_storage_version: 1, new_storage_version: 2, old_attachments_path: old_attachments_path, new_attachments_path: new_attachments_path) }

  before do
    TestEnv.clean_test_path
  end

  describe '#create!' do
    it_behaves_like 'a Geo event store', Geo::HashedStorageAttachmentsEvent

    context 'when running on a primary node' do
      before do
        stub_primary_node
      end

      it 'tracks project attributes' do
        subject.create!

        expect(Geo::HashedStorageAttachmentsEvent.last).to have_attributes(
          old_attachments_path: old_attachments_path,
          new_attachments_path: new_attachments_path
        )
      end
    end
  end
end
