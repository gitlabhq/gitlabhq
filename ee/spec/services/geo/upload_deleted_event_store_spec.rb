# frozen_string_literal: true

require 'spec_helper'

describe Geo::UploadDeletedEventStore do
  include EE::GeoHelpers

  set(:secondary_node) { create(:geo_node) }

  let(:upload) { create(:upload) }

  subject { described_class.new(upload) }

  describe '#create!' do
    it_behaves_like 'a Geo event store', Geo::UploadDeletedEvent do
      let(:file_subject) { upload }
    end

    context 'when running on a primary node' do
      before do
        stub_primary_node
      end

      it 'tracks upload attributes' do
        subject.create!

        expect(Geo::UploadDeletedEvent.last).to have_attributes(
          upload_id: upload.id,
          file_path: upload.path,
          model_id: upload.model_id,
          model_type: upload.model_type,
          uploader: upload.uploader
        )
      end
    end
  end
end
