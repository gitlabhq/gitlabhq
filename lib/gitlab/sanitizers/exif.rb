# frozen_string_literal: true

module Gitlab
  module Sanitizers
    class Exif
      # these tags are not removed from the image
      ALLOWLISTED_TAGS = %w[
        ResolutionUnit
        XResolution
        YResolution
        YCbCrSubSampling
        YCbCrPositioning
        BitsPerSample
        ImageHeight
        ImageWidth
        ImageSize
        Orientation
      ].freeze

      EXCLUDE_PARAMS = ALLOWLISTED_TAGS.map { |tag| "-#{tag}" }
      ALLOWED_MIME_TYPES = %w[image/jpeg image/tiff].freeze

      attr_reader :logger

      def initialize(logger: Gitlab::AppLogger)
        @logger = logger
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def batch_clean(start_id: nil, stop_id: nil, dry_run: true, sleep_time: nil, uploader: nil, since: nil)
        relation = Upload.where('lower(path) like ? or lower(path) like ? or lower(path) like ?',
          '%.jpg', '%.jpeg', '%.tiff')
        relation = relation.where(uploader: uploader) if uploader
        relation = relation.where('created_at > ?', since) if since

        logger.info "running in dry run mode, no images will be rewritten" if dry_run

        find_params = {
          start: start_id.present? ? start_id.to_i : nil,
          finish: stop_id.present? ? stop_id.to_i : Upload.last&.id,
          batch_size: 1000
        }

        relation.find_each(**find_params) do |upload|
          clean(upload.retrieve_uploader, dry_run: dry_run)
          sleep sleep_time if sleep_time
        rescue StandardError => err
          logger.error "failed to sanitize #{upload_ref(upload)}: #{err.message}"
          logger.debug err.backtrace.join("\n ")
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def clean(uploader, dry_run: true)
        Dir.mktmpdir('gitlab-exif') do |tmpdir|
          src_path = fetch_upload_to_file(uploader, tmpdir)

          break if dry_run

          remove_and_store(tmpdir, src_path, uploader)
        end
      end

      def clean_existing_path(src_path, dry_run: false, content: nil, skip_unallowed_types: false)
        content ||= File.read(src_path)

        if skip_unallowed_types
          return unless check_for_allowed_types(content, raise_error: false)
        else
          check_for_allowed_types(content)
        end

        return if dry_run

        exec_remove_exif!(src_path)
      end

      private

      def remove_and_store(tmpdir, src_path, uploader)
        exec_remove_exif!(src_path)
        logger.info "#{upload_ref(uploader.upload)}: exif removed, storing"
        File.open(src_path, 'r') { |f| uploader.store!(f) }
      end

      def exec_remove_exif!(path)
        [
          ["exiftool", "-IPTC=", "-XMP=", path],
          ["exiftool", "-all=", "-tagsFromFile", "@", *EXCLUDE_PARAMS, path]
        ].each do |cmd|
          output, status = Gitlab::Popen.popen(cmd)

          if status != 0
            raise "exiftool return code is #{status}: #{output}"
          end
        end

        if File.size(path) == 0
          raise "size of file is 0"
        end

        # exiftool creates backup of the original file in filename_original
        old_path = "#{path}_original"
        if File.size(path) == File.size(old_path)
          raise "size of sanitized file is same as original size"
        end
      end

      def fetch_upload_to_file(uploader, dir)
        # upload is stored into the file with the original name - this filename
        # is used by carrierwave when storing the file back to the storage
        filename = File.join(dir, uploader.filename)
        contents = uploader.read

        check_for_allowed_types(contents)

        File.open(filename, 'w') do |file|
          file.binmode
          file.write contents
        end

        filename
      end

      def check_for_allowed_types(contents, raise_error: true)
        mime_type = ::Gitlab::Utils::MimeType.from_string(contents)

        allowed = ALLOWED_MIME_TYPES.include?(mime_type)
        if !allowed && raise_error
          raise "File type #{mime_type} not supported. Only supports #{ALLOWED_MIME_TYPES.join(', ')}."
        end

        allowed
      end

      def upload_ref(upload)
        "#{upload.id}:#{upload.path}"
      end
    end
  end
end
