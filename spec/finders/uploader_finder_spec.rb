# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UploaderFinder do
  describe '#execute' do
    let(:project) { build(:project) }
    let(:upload) { create(:upload, :issuable_upload, :with_file) }
    let(:secret) { upload.secret }
    let(:file_name) { upload.path }

    subject { described_class.new(project, secret, file_name).execute }

    before do
      upload.save!
    end

    context 'when successful' do
      before do
        allow_next_instance_of(FileUploader) do |uploader|
          allow(uploader).to receive(:retrieve_from_store!).with(upload.path).and_return(uploader)
        end
      end

      it 'gets the file-like uploader' do
        expect(subject).to be_an_instance_of(FileUploader)
        expect(subject.model).to eq(project)
        expect(subject.secret).to eq(secret)
      end
    end

    context 'when path traversal in file name' do
      before do
        upload.path = '/uploads/11111111111111111111111111111111/../../../../../../../../../../../../../../etc/passwd)'
        upload.save!
      end

      it 'returns nil' do
        expect(subject).to be(nil)
      end
    end

    context 'when unexpected failure' do
      before do
        allow_next_instance_of(FileUploader) do |uploader|
          allow(uploader).to receive(:retrieve_from_store!).and_raise(StandardError)
        end
      end

      it 'returns nil when unexpected error is raised' do
        expect { subject }.to raise_error(StandardError)
      end
    end
  end
end
