# frozen_string_literal: true

module Backup
  module Helper
    include ::Gitlab::Utils::StrongMemoize

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
