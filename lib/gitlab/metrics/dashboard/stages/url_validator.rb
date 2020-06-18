# frozen_string_literal: true

module Gitlab
  module Metrics
    module Dashboard
      module Stages
        class UrlValidator < BaseStage
          def transform!
            dashboard[:links]&.each do |link|
              Gitlab::UrlBlocker.validate!(link[:url])
            rescue Gitlab::UrlBlocker::BlockedUrlError
              link[:url] = ''
            end
          end
        end
      end
    end
  end
end
