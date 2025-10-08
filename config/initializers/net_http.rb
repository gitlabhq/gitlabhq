# frozen_string_literal: true

MONKEY_PATCH_METHOD_CHECKSUM = "7fd222f9cffc7ab25d4782d380fdb0b5e83b35d495f9e2fbd8e5057891c73108"

unless Rails.env.production?
  source = "Net::HTTPResponse::Inflater".safe_constantize&.instance_method(:inflate_adapter)&.source.to_s.strip

  unless OpenSSL::Digest::SHA256.hexdigest(source) == MONKEY_PATCH_METHOD_CHECKSUM
    raise "Original Net::HTTPResponse::Inflater code was modified. Please update the patch accordingly, then update" \
      "the checksum."
  end
end

module Net
  class HTTPResponse
    # This is a monkey patch over an existing method of net/http to limit maximum decompression size
    #
    # To disable the decomposition limit validation see `::Gitlab::HTTP.without_decompression_limit`.
    #
    # Original code from
    # https://github.com/ruby/ruby/blob/d5f94941d87743d6563fa1a038665917dea70201/lib/net/http/response.rb#L693-L707
    class Inflater
      def inflate_adapter(dest)
        if dest.respond_to?(:set_encoding)
          dest.set_encoding(Encoding::ASCII_8BIT)
        elsif dest.respond_to?(:force_encoding)
          dest.force_encoding(Encoding::ASCII_8BIT)
        end

        block = proc do |compressed_chunk|
          @inflate.inflate(compressed_chunk) do |chunk|
            compressed_chunk.clear

            if validate_decompressed_size? && @inflate.total_out > max_http_decompressed_size
              Gitlab::AppJsonLogger.error(message: 'Net::HTTP - Response size too large', size: @inflate.total_out,
                caller: Gitlab::BacktraceCleaner.clean_backtrace(caller))

              raise Gitlab::HTTP::MaxDecompressionSizeError, "Response size over #{max_http_decompressed_size} bytes"
            end

            dest << chunk
          end
        end

        Net::ReadAdapter.new(block)
      end

      def validate_decompressed_size?
        Gitlab::CurrentSettings.max_http_decompressed_size > 0 &&
          !Gitlab::SafeRequestStore[:disable_net_http_decompression]
      end

      def max_http_decompressed_size
        Gitlab::CurrentSettings.max_http_decompressed_size.megabytes
      end
    end
  end

  class HTTPInformation < Net::HTTPResponse
    # This is a monkey patch over an existing method of net/http to reject Net::HTTPInformation responses
    #
    # Original code from
    # https://github.com/ruby/ruby/blob/98aa2a6608b026c56130154aa07b1635e05d95e8/lib/net/http/responses.rb#L21-24
    def initialize(_httpv, _code, _msg)
      raise Gitlab::HTTP::InvalidResponseError, "Invalid server response: 1xx responses not supported"
    end
  end
end
