# coding: utf-8
# frozen_string_literal: true

require 'spec_helper'

describe SendFileUpload do
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
        # Notice the filename= is omitted from the disposition; this is because
        # Rails 5 will append this header in send_file
        expected_params = {
          filename: 'test.png',
          disposition: "inline; filename*=UTF-8''test.png"
        }
        expect(controller).to receive(:send_file).with(uploader.path, expected_params)

        subject
      end
    end

    context 'with attachment' do
      let(:filename) { 'test.js' }
      let(:params) { { attachment: filename } }

      it 'sends a file with content-type of text/plain' do
        # Notice the filename= is omitted from the disposition; this is because
        # Rails 5 will append this header in send_file
        expected_params = {
          content_type: 'text/plain',
          filename: 'test.js',
          disposition: "attachment; filename*=UTF-8''test.js"
        }
        expect(controller).to receive(:send_file).with(uploader.path, expected_params)

        subject
      end

      context 'with non-ASCII encoded filename' do
        let(:filename) { 'テスト.txt' }

        # Notice the filename= is omitted from the disposition; this is because
        # Rails 5 will append this header in send_file
        it 'sends content-disposition for non-ASCII encoded filenames' do
          expected_params = {
            filename: filename,
            disposition: "attachment; filename*=UTF-8''%E3%83%86%E3%82%B9%E3%83%88.txt"
          }
          expect(controller).to receive(:send_file).with(uploader.path, expected_params)

          subject
        end
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
          expected_headers = /response-content-disposition=attachment%3B%20filename%3D%22test.js%22%3B%20filename%2A%3DUTF-8%27%27test.js&response-content-type=application%2Fecmascript/
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
