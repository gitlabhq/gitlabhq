module Gitlab
  module Ci
    class Trace
      module ChunkStores
        class ObjectStorage < Base
          class << self
            def open(job_id, chunk_index, **params)
              raise ArgumentError unless job_id && chunk_index

              yield self.class.new(params)
            end

            def exist?(job_id, chunk_index)
              raise NotSupportedError
            end

            def chunks_count(job_id)
              raise NotSupportedError
            end
          end

          InvalidURLError = Class.new(StandardError)
          FailedToGetChunkError = Class.new(StandardError)

          attr_reader :url

          def initialize(**params)
            raise InvalidURLError unless ::Gitlab::UrlSanitizer.valid?(url)

            super

            @uri = URI(url)
          end

          def get
            response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
              request = Net::HTTP::Get.new(uri)
              request.set_range(chunk_start, buffer_size)
              http.request(request)
            end

            raise FailedToGetChunkError unless response.code == '200' || response.code == '206'

            response.body.force_encoding(Encoding::BINARY)
          end

          def size
            raise NotImplementedError
          end

          def write!(data)
            raise NotImplementedError
          end

          def truncate!(offset)
            raise NotImplementedError
          end

          def delete
            raise NotImplementedError
          end

          def change_chunk_index!(job_id, new_chunk_index)
            raise NotImplementedError
          end
        end
      end
    end
  end
end
