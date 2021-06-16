# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module SizeLimiter
      class Server
        def call(worker, job, queue)
          # This middleware should always decompress jobs regardless of the
          # limiter mode or size limit. Otherwise, this could leave compressed
          # payloads in queues that are then not able to be processed.
          ::Gitlab::SidekiqMiddleware::SizeLimiter::Compressor.decompress(job)

          yield
        end
      end
    end
  end
end
