# frozen_string_literal: true

module API
  module Helpers
    module Packages
      module Rubygems
        # Sets the `X-Error-Message` response header on RubyGems error responses.
        #
        # `Gem::RemoteFetcher#fetch_http` reads this header and uses its value in place
        # of the HTTP reason phrase, so `gem install`/`gem fetch` users see a meaningful
        # detail instead of a generic "Bad response Forbidden 403". The response body is
        # left unchanged.
        module ErrorMessageHeader
          extend ::Gitlab::Utils::Override
          include ::API::Helpers::Packages::ErrorMessage

          HEADER_NAME = 'X-Error-Message'

          override :render_structured_api_error!
          def render_structured_api_error!(hash, status)
            return super unless Feature.enabled?(:rubygems_error_message_header, Feature.current_request)

            detail = error_detail(Rack::Utils.status_code(status), hash['message'])
            header[HEADER_NAME] = error_message_single_line(detail) if detail.present?

            super
          end

          private

          def error_detail(status_code, message)
            return if status_code < 400
            return if message.blank?
            return unless message.is_a?(String)

            detail = error_message_detail(message)
            return detail if detail

            # Bare "NNN StatusPhrase" (e.g. "403 Forbidden") carries no detail beyond the
            # HTTP reason phrase the gem client already shows, so skip the header. A message
            # that merely starts with three digits and a space (e.g. a gem literally named
            # "404" yielding "404 not found") is also skipped; this is an accepted
            # limitation. Matching the exact phrase instead is unreliable because the bare
            # phrases are hardcoded inconsistently (e.g. bad_request! emits "400 Bad request",
            # not Rack's "400 Bad Request"), and purely numeric gem names are not expected.
            return if message.match?(/\A\d{3}\s/)

            # Custom message with no status prefix (e.g. the dependency resolver's
            # "forbidden" or "<gem> not found") -> use verbatim.
            message
          end
        end
      end
    end
  end
end
