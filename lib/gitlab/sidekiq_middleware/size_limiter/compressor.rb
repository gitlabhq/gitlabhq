# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module SizeLimiter
      class Compressor
        PayloadDecompressionConflictError = Class.new(StandardError)
        PayloadDecompressionError = Class.new(StandardError)

        # Level 5 is a good trade-off between space and time
        # https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1054#note_568129605
        COMPRESS_LEVEL = 5
        ORIGINAL_SIZE_KEY = 'original_job_size_bytes'
        COMPRESSED_KEY = 'compressed'

        def self.compressed?(job)
          job&.has_key?(COMPRESSED_KEY)
        end

        def self.compress(job, job_args)
          compressed_args = Base64.strict_encode64(Zlib::Deflate.deflate(job_args, COMPRESS_LEVEL))

          job[COMPRESSED_KEY] = true
          job[ORIGINAL_SIZE_KEY] = job_args.bytesize
          job['args'] = [compressed_args]

          compressed_args
        end

        def self.decompress(job)
          return unless compressed?(job)

          validate_args!(job)

          job.except!(ORIGINAL_SIZE_KEY, COMPRESSED_KEY)
          job['args'] = Gitlab::Json.load(Zlib::Inflate.inflate(Base64.strict_decode64(job['args'].first)))
        rescue Zlib::Error
          raise PayloadDecompressionError, 'Fail to decompress Sidekiq job payload'
        end

        def self.validate_args!(job)
          if job['args'] && job['args'].length != 1
            exception = PayloadDecompressionConflictError.new('Sidekiq argument list should include 1 argument.\
                                                              This means that there is another a middleware interfering with the job payload.\
                                                              That conflicts with the payload compressor')
            ::Gitlab::ErrorTracking.track_and_raise_exception(exception)
          end
        end
      end
    end
  end
end
