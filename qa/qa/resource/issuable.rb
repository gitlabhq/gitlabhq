# frozen_string_literal: true

module QA
  module Resource
    class Issuable < Base
      using Rainbow

      # Comments (notes) path
      #
      # @return [String]
      def api_comments_path
        "#{api_get_path}/notes"
      end

      # Get issue comments
      #
      # @return [Array]
      def comments(auto_paginate: false, attempts: 0)
        Runtime::Logger.debug("Fetching comments for #{self.class.name.black.bg(:white)} with path '#{api_get_path}'")
        return parse_body(api_get_from(api_comments_path)) unless auto_paginate

        auto_paginated_response(
          Runtime::API::Request.new(api_client, api_comments_path, per_page: '100').url,
          attempts: attempts
        )
      end

      # Create a new comment
      #
      # @param [String] body
      # @param [Boolean] confidential
      # @return [Hash]
      def add_comment(body:, confidential: false)
        api_post_to(api_comments_path, body: body, confidential: confidential)
      end

      # Issue label events
      #
      # @param [Boolean] auto_paginate
      # @param [Integer] attempts
      # @return [Array<Hash>]
      def label_events(auto_paginate: false, attempts: 0)
        events("label", auto_paginate: auto_paginate, attempts: attempts)
      end

      # Issue state events
      #
      # @param [Boolean] auto_paginate
      # @param [Integer] attempts
      # @return [Array<Hash>]
      def state_events(auto_paginate: false, attempts: 0)
        events("state", auto_paginate: auto_paginate, attempts: attempts)
      end

      # Issue milestone events
      #
      # @param [Boolean] auto_paginate
      # @param [Integer] attempts
      # @return [Array<Hash>]
      def milestone_events(auto_paginate: false, attempts: 0)
        events("milestone", auto_paginate: auto_paginate, attempts: attempts)
      end

      private

      # Issue events
      #
      # @param [String] name event name
      # @param [Boolean] auto_paginate
      # @param [Integer] attempts
      # @return [Array<Hash>]
      def events(name, auto_paginate:, attempts:)
        return parse_body(api_get_from("#{api_get_path}/resource_#{name}_events")) unless auto_paginate

        auto_paginated_response(
          Runtime::API::Request.new(api_client, "#{api_get_path}/resource_#{name}_events", per_page: '100').url,
          attempts: attempts
        )
      end
    end
  end
end
