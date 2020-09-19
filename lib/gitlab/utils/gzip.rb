# frozen_string_literal: true

module Gitlab
  module Utils
    module Gzip
      def gzip_compress(data)
        # .compress returns ASCII-8BIT, so we need to force the encoding to
        #   UTF-8 before caching it in redis, else we risk encoding mismatch
        #   errors.
        #
        ActiveSupport::Gzip.compress(data).force_encoding("UTF-8")
      rescue Zlib::GzipFile::Error
        data
      end

      def gzip_decompress(data)
        # Since we could be dealing with an already populated cache full of data
        #   that isn't gzipped, we want to also check to see if the data is
        #   gzipped before we attempt to .decompress it, thus we check the first
        #   2 bytes for "\x1F\x8B" to confirm it is a gzipped string. While a
        #   non-gzipped string will raise a Zlib::GzipFile::Error, which we're
        #   rescuing, we don't want to count on rescue for control flow.
        #
        data[0..1] == "\x1F\x8B" ? ActiveSupport::Gzip.decompress(data) : data
      rescue Zlib::GzipFile::Error
        data
      end
    end
  end
end
