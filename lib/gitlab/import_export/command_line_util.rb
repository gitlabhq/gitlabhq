# frozen_string_literal: true

module Gitlab
  module ImportExport
    module CommandLineUtil
      UNTAR_MASK = 'u+rwX,go+rX,go-w'
      DEFAULT_DIR_MODE = 0700

      def tar_czf(archive:, dir:)
        tar_with_options(archive: archive, dir: dir, options: 'czf')
      end

      def untar_zxf(archive:, dir:)
        untar_with_options(archive: archive, dir: dir, options: 'zxf')
      end

      def gzip(dir:, filename:)
        gzip_with_options(dir: dir, filename: filename)
      end

      def gunzip(dir:, filename:)
        gzip_with_options(dir: dir, filename: filename, options: 'd')
      end

      def gzip_with_options(dir:, filename:, options: nil)
        filepath = File.join(dir, filename)
        cmd = %W(gzip #{filepath})
        cmd << "-#{options}" if options

        _, status = Gitlab::Popen.popen(cmd)

        if status == 0
          status
        else
          raise Gitlab::ImportExport::Error.file_compression_error
        end
      end

      def mkdir_p(path)
        FileUtils.mkdir_p(path, mode: DEFAULT_DIR_MODE)
        FileUtils.chmod(DEFAULT_DIR_MODE, path)
      end

      private

      def download_or_copy_upload(uploader, upload_path)
        if uploader.upload.local?
          copy_files(uploader.path, upload_path)
        else
          download(uploader.url, upload_path)
        end
      end

      def download(url, upload_path)
        File.open(upload_path, 'w') do |file|
          # Download (stream) file from the uploader's location
          IO.copy_stream(URI.parse(url).open, file)
        end
      end

      def tar_with_options(archive:, dir:, options:)
        execute(%W(tar -#{options} #{archive} -C #{dir} .))
      end

      def untar_with_options(archive:, dir:, options:)
        execute(%W(tar -#{options} #{archive} -C #{dir}))
        execute(%W(chmod -R #{UNTAR_MASK} #{dir}))
      end

      def execute(cmd)
        output, status = Gitlab::Popen.popen(cmd)
        @shared.error(Gitlab::ImportExport::Error.new(output.to_s)) unless status == 0 # rubocop:disable Gitlab/ModuleWithInstanceVariables
        status == 0
      end

      def git_bin_path
        Gitlab.config.git.bin_path
      end

      def copy_files(source, destination)
        # if we are copying files, create the destination folder
        destination_folder = File.file?(source) ? File.dirname(destination) : destination

        mkdir_p(destination_folder)
        FileUtils.copy_entry(source, destination)
        true
      end
    end
  end
end
