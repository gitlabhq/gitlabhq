# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SendFileUpload do
  let(:uploader_class) do
    Class.new(GitlabUploader) do
      include ObjectStorage::Concern

      storage_options Gitlab.config.uploads

      private

      # user/:id
      def dynamic_segment
        File.join(model.class.underscore, model.id.to_s)
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
    let(:params) { {} }

    subject { controller.send_upload(uploader, **params) }

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

    context 'with inline image' do
      let(:filename) { 'test.png' }
      let(:params) { { disposition: 'inline', attachment: filename } }

      it 'sends a file with inline disposition' do
        expected_params = {
          filename: 'test.png',
          disposition: 'inline'
        }
        expect(controller).to receive(:send_file).with(uploader.path, expected_params)

        subject
      end
    end

    context 'with attachment' do
      let(:filename) { 'test.js' }
      let(:params) { { attachment: filename } }

      it 'sends a file with content-type of text/plain' do
        expected_params = {
          content_type: 'text/plain',
          filename: 'test.js',
          disposition: 'attachment'
        }
        expect(controller).to receive(:send_file).with(uploader.path, expected_params)

        subject
      end

      context 'with a proxied file in object storage' do
        before do
          stub_uploads_object_storage(uploader: uploader_class)
          uploader.object_store = ObjectStorage::Store::REMOTE
          uploader.store!(temp_file)
          allow(Gitlab.config.uploads.object_store).to receive(:proxy_download) { true }
        end

        it 'sends a file with a custom type' do
          headers = double
          expected_headers = /response-content-disposition=attachment%3B%20filename%3D%22test.js%22%3B%20filename%2A%3DUTF-8%27%27test.js&response-content-type=application%2Fjavascript/
          expect(Gitlab::Workhorse).to receive(:send_url).with(expected_headers).and_call_original
          expect(headers).to receive(:store).with(Gitlab::Workhorse::SEND_DATA_HEADER, /^send-url:/)

          expect(controller).not_to receive(:send_file)
          expect(controller).to receive(:headers) { headers }
          expect(controller).to receive(:head).with(:ok)

          subject
        end
      end
    end

    context 'when remote file is used' do
      before do
        stub_uploads_object_storage(uploader: uploader_class)
        uploader.object_store = ObjectStorage::Store::REMOTE
        uploader.store!(temp_file)
      end

      shared_examples 'proxied file' do
        it 'sends a file' do
          headers = double
          expect(Gitlab::Workhorse).not_to receive(:send_url).with(/response-content-disposition/)
          expect(Gitlab::Workhorse).not_to receive(:send_url).with(/response-content-type/)
          expect(Gitlab::Workhorse).to receive(:send_url).and_call_original

          expect(headers).to receive(:store).with(Gitlab::Workhorse::SEND_DATA_HEADER, /^send-url:/)
          expect(controller).not_to receive(:send_file)
          expect(controller).to receive(:headers) { headers }
          expect(controller).to receive(:head).with(:ok)

          subject
        end
      end

      context 'and proxying is enabled' do
        before do
          allow(Gitlab.config.uploads.object_store).to receive(:proxy_download) { true }
        end

        it_behaves_like 'proxied file'
      end

      context 'and proxying is disabled' do
        before do
          allow(Gitlab.config.uploads.object_store).to receive(:proxy_download) { false }
        end

        it 'sends a file' do
          expect(controller).to receive(:redirect_to).with(/#{uploader.path}/)

          subject
        end

        context 'with proxy requested' do
          let(:params) { { proxy: true } }

          it_behaves_like 'proxied file'
        end
      end
    end
  end
end
