module Gitlab
  module Ci
    class Trace
      module ChunkedFile
        module ChunkStore
          class ObjectStorage < Base
            class << self
              def open(job_id, chunk_index, **params)
                raise ArgumentError unless job_id && chunk_index

                relative_path = relative_path(job_id, chunk_index)
                store = self.new(relative_path, params)

                yield store
              ensure
                store&.close
              end

              def exist?(job_id, chunk_index)
                raise NotImplementedError
              end

              def chunks_count(job_id)
                raise NotImplementedError
              end

              def relative_path(job_id, chunk_index)
                "#{job_id}/#{chunk_index}.chunk"
              end
            end

            FailedToGetChunkError = Class.new(StandardError)

            attr_reader :relative_path

            def initialize(relative_path, **params)
              super

              @relative_path = relative_path
            end

            def close
              @relative_path = nil
            end

            ## TODO: Carrierwave::Fog integration
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
              raise NotImplementedError, 'Partial write is not supported' unless buffer_size == data.length
              raise NotImplementedError
            end

            def append!(data)
              raise NotImplementedError
            end

            def truncate!(offset)
              raise NotImplementedError
            end

            def delete!
              raise NotImplementedError
            end
          end
        end
      end
    end
  end
end
