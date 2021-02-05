# frozen_string_literal: true

::Faraday::Request.register_middleware(gitlab_error_callback: -> { ::Gitlab::Faraday::ErrorCallback })
