require 'spec_helper'

describe SendFileUpload do
  let(:uploader_class) do
    Class.new(GitlabUploader) do
      include ObjectStorage::Concern

      storage_options Gitlab.config.uploads

      private

      # user/:id
      def dynamic_segment
        File.join(model.class.to_s.underscore, model.id.to_s)
      end
    end
  end

  let(:controller_class) do
    Class.new do
      include SendFileUpload
    end
  end

  let(:object) { build_stubbed(:user) }
  let(:uploader) { uploader_class.new(object, :file) }

  describe '#send_upload' do
    let(:controller) { controller_class.new }
    let(:temp_file) { Tempfile.new('test') }

    subject { controller.send_upload(uploader) }

    before do
      FileUtils.touch(temp_file)
    end

    after do
      FileUtils.rm_f(temp_file)
    end

    context 'when local file is used' do
      before do
        uploader.store!(temp_file)
      end

      it 'sends a file' do
        expect(controller).to receive(:send_file).with(uploader.path, anything)

        subject
      end
    end

    context 'when remote file is used' do
      before do
        stub_uploads_object_storage(uploader: uploader_class)
        uploader.object_store = ObjectStorage::Store::REMOTE
        uploader.store!(temp_file)
      end

      context 'and proxying is enabled' do
        before do
          allow(Gitlab.config.uploads.object_store).to receive(:proxy_download) { true }
        end

        it 'sends a file' do
          headers = double
          expect(headers).to receive(:store).with(Gitlab::Workhorse::SEND_DATA_HEADER, /^send-url:/)
          expect(controller).to receive(:headers) { headers }
          expect(controller).to receive(:head).with(:ok)

          subject
        end
      end

      context 'and proxying is disabled' do
        before do
          allow(Gitlab.config.uploads.object_store).to receive(:proxy_download) { false }
        end

        it 'sends a file' do
          expect(controller).to receive(:redirect_to).with(/#{uploader.path}/)

          subject
        end
      end
    end
  end
end
