# frozen_string_literal: true

module Gitlab
  module Chat
    module Responder
      class Base
        attr_reader :build

        # build - The `Ci::Build` that was executed.
        def initialize(build)
          @build = build
        end

        def pipeline
          build.pipeline
        end

        def project
          pipeline.project
        end

        def success(*)
          raise NotImplementedError, 'You must implement #success(output)'
        end

        def failure
          raise NotImplementedError, 'You must implement #failure'
        end

        def send_response(output)
          raise NotImplementedError, 'You must implement #send_response(output)'
        end

        def scheduled_output
          raise NotImplementedError, 'You must implement #scheduled_output'
        end
      end
    end
  end
end
