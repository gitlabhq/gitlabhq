# frozen_string_literal: true

module Backup
  module Helper
    include ::Gitlab::Utils::StrongMemoize

    def access_denied_error(path)
      message = <<~EOS

      ### NOTICE ###
      As part of restore, the task tried to move existing content from #{path}.
      However, it seems that directory contains files/folders that are not owned
      by the user #{Gitlab.config.gitlab.user}. To proceed, please move the files
      or folders inside #{path} to a secure location so that #{path} is empty and
      run restore task again.

      EOS
      raise message
    end

    def resource_busy_error(path)
      message = <<~EOS

      ### NOTICE ###
      As part of restore, the task tried to rename `#{path}` before restoring.
      This could not be completed, perhaps `#{path}` is a mountpoint?

      To complete the restore, please move the contents of `#{path}` to a
      different location and run the restore task again.

      EOS
      raise message
    end

    def compress_cmd
      if ENV['COMPRESS_CMD'].present?
        puts "Using custom COMPRESS_CMD '#{ENV['COMPRESS_CMD']}'"
        puts "Ignoring GZIP_RSYNCABLE" if ENV['GZIP_RSYNCABLE'] == 'yes'
        ENV['COMPRESS_CMD']
      elsif ENV['GZIP_RSYNCABLE'] == 'yes'
        "gzip --rsyncable -c -1"
      else
        "gzip -c -1"
      end
    end
    strong_memoize_attr :compress_cmd

    def decompress_cmd
      if ENV['DECOMPRESS_CMD'].present?
        puts "Using custom DECOMPRESS_CMD '#{ENV['DECOMPRESS_CMD']}'"
        ENV['DECOMPRESS_CMD']
      else
        "gzip -cd"
      end
    end
    strong_memoize_attr :decompress_cmd
  end
end
