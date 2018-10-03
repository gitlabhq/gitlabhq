require 'spec_helper'

describe Appearance do
  include ::EE::GeoHelpers

  subject { build(:appearance) }

  describe 'validations' do
    let(:triplet) { '#000' }
    let(:hex)     { '#AABBCC' }

    it { is_expected.to allow_value(nil).for(:message_background_color) }
    it { is_expected.to allow_value(triplet).for(:message_background_color) }
    it { is_expected.to allow_value(hex).for(:message_background_color) }
    it { is_expected.not_to allow_value('000').for(:message_background_color) }

    it { is_expected.to allow_value(nil).for(:message_font_color) }
    it { is_expected.to allow_value(triplet).for(:message_font_color) }
    it { is_expected.to allow_value(hex).for(:message_font_color) }
    it { is_expected.not_to allow_value('000').for(:message_font_color) }
  end

  context 'object storage with background upload' do
    context 'when running in a Geo primary node' do
      set(:primary) { create(:geo_node, :primary) }
      set(:secondary) { create(:geo_node) }

      before do
        stub_current_geo_node(primary)
        stub_uploads_object_storage(AttachmentUploader, background_upload: true)
      end

      it 'creates a Geo deleted log event for logo' do
        Sidekiq::Testing.inline! do
          expect do
            create(:appearance, :with_logo)
          end.to change(Geo::UploadDeletedEvent, :count).by(1)
        end
      end

      it 'creates a Geo deleted log event for header logo' do
        Sidekiq::Testing.inline! do
          expect do
            create(:appearance, :with_header_logo)
          end.to change(Geo::UploadDeletedEvent, :count).by(1)
        end
      end

      it 'creates only a Geo deleted log event for the migrated header logo' do
        Sidekiq::Testing.inline! do
          appearance = create(:appearance, :with_header_logo, :with_logo)

          expect do
            appearance.update(header_logo: fixture_file_upload('spec/fixtures/rails_sample.jpg'))
          end.to change(Geo::UploadDeletedEvent, :count).by(1)
        end
      end
    end
  end
end
