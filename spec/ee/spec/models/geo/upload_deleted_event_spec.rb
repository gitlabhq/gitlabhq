require 'spec_helper'

RSpec.describe Geo::UploadDeletedEvent, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:upload) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:upload) }
    it { is_expected.to validate_presence_of(:file_path) }
    it { is_expected.to validate_presence_of(:model_id) }
    it { is_expected.to validate_presence_of(:model_type) }
    it { is_expected.to validate_presence_of(:uploader) }
  end

  describe '#upload_type' do
    it 'returns nil when uploader is not set' do
      subject.uploader = nil

      expect(subject.upload_type).to be_nil
    end

    it 'returns uploader type when uploader is set' do
      subject.uploader = 'PersonalFileUploader'

      expect(subject.upload_type).to eq 'personal_file'
    end
  end
end
