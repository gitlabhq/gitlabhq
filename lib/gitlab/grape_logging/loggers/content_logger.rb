# frozen_string_literal: true

module Gitlab
  module GrapeLogging
    module Loggers
      class ContentLogger < ::GrapeLogging::Loggers::Base
        def parameters(request, _)
          {
            content_length: request.env['CONTENT_LENGTH'],
            content_range: request.env['HTTP_CONTENT_RANGE']
          }.compact
        end
      end
    end
  end
end
