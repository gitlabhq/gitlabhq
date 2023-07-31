# frozen_string_literal: true

module Gitlab
  module ImportExport
    module CommandLineUtil
      UNTAR_MASK = 'u+rwX,go+rX,go-w'
      DEFAULT_DIR_MODE = 0700

      FileOversizedError = Class.new(StandardError)

      def tar_czf(archive:, dir:)
        tar_with_options(archive: archive, dir: dir, options: 'czf')
      end

      def untar_zxf(archive:, dir:)
        untar_with_options(archive: archive, dir: dir, options: 'zxf')
      end

      def tar_cf(archive:, dir:)
        tar_with_options(archive: archive, dir: dir, options: 'cf')
      end

      def untar_xf(archive:, dir:)
        untar_with_options(archive: archive, dir: dir, options: 'xf')
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

      def download_or_copy_upload(uploader, upload_path, size_limit: nil)
        if uploader.upload.local?
          copy_files(uploader.path, upload_path)
        else
          download(uploader.url, upload_path, size_limit: size_limit)
        end
      end

      def download(url, upload_path, size_limit: nil)
        File.open(upload_path, 'wb') do |file|
          current_size = 0

          Gitlab::HTTP.get(url, stream_body: true, allow_object_storage: true) do |fragment|
            if [301, 302, 303, 307].include?(fragment.code)
              Gitlab::Import::Logger.warn(message: "received redirect fragment", fragment_code: fragment.code)
            elsif fragment.code == 200
              current_size += fragment.bytesize

              raise FileOversizedError if size_limit.present? && current_size > size_limit

              file.write(fragment)
            else
              raise Gitlab::ImportExport::Error, "unsupported response downloading fragment #{fragment.code}"
            end
          end
        end
      rescue FileOversizedError
        nil
      end

      def tar_with_options(archive:, dir:, options:)
        execute_cmd(%W(tar -#{options} #{archive} -C #{dir} .))
      end

      def untar_with_options(archive:, dir:, options:)
        execute_cmd(%W(tar -#{options} #{archive} -C #{dir}))
        execute_cmd(%W(chmod -R #{UNTAR_MASK} #{dir}))
        remove_symlinks(dir)
      end

      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      def execute_cmd(cmd)
        output, status = Gitlab::Popen.popen(cmd)

        return true if status == 0

        output = output&.strip
        message = "command exited with error code #{status}"
        message += ": #{output}" if output.present?

        if @shared.respond_to?(:error)
          @shared.error(Gitlab::ImportExport::Error.new(message))

          false
        else
          raise Gitlab::ImportExport::Error, message
        end
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables

      def copy_files(source, destination)
        # if we are copying files, create the destination folder
        destination_folder = File.file?(source) ? File.dirname(destination) : destination

        mkdir_p(destination_folder)
        FileUtils.copy_entry(source, destination)
        true
      end

      def remove_symlinks(dir)
        ignore_file_names = %w[. ..]

        # Using File::FNM_DOTMATCH to also delete symlinks starting with "."
        Dir.glob("#{dir}/**/*", File::FNM_DOTMATCH)
          .reject { |f| ignore_file_names.include?(File.basename(f)) }
          .each do |filepath|
            FileUtils.rm(filepath) if File.lstat(filepath).symlink?
          end

        true
      end
    end
  end
end
