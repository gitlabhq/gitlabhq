# frozen_string_literal: true

module Uploads
  class Local < Base
    def keys(relation)
      relation.includes(:model).find_each.map(&:absolute_path)
    end

    def delete_keys(keys)
      keys.each do |path|
        delete_file(path)
      end
    end

    private

    def delete_file(path)
      unless exists?(path)
        logger.warn("File '#{path}' doesn't exist, skipping")
        return
      end

      unless in_uploads?(path)
        message = "Path '#{path}' is not in uploads dir, skipping"
        logger.warn(message)
        Gitlab::Sentry.track_and_raise_for_dev_exception(
          RuntimeError.new(message), uploads_dir: storage_dir)
        return
      end

      FileUtils.rm(path)
      delete_dir!(File.dirname(path))
    end

    def exists?(path)
      path.present? && File.exist?(path)
    end

    def in_uploads?(path)
      path.start_with?(storage_dir)
    end

    def delete_dir!(path)
      Dir.rmdir(path)
    rescue Errno::ENOENT
      # Ignore: path does not exist
    rescue Errno::ENOTDIR
      # Ignore: path is not a dir
    rescue Errno::ENOTEMPTY, Errno::EEXIST
      # Ignore: dir is not empty
    end

    def storage_dir
      @storage_dir ||= File.realpath(Gitlab.config.uploads.storage_path)
    end
  end
end
