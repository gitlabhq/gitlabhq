# frozen_string_literal: true

module Gitlab
  module DependencyLinker
    class JsonLinker < BaseLinker
      def link
        return highlighted_text unless json

        super
      end

      private

      # Links package names in a JSON key or values.
      #
      # Example:
      #   link_json('name')
      #   # Will link `package` in `"name": "package"`
      #
      #   link_json('name', 'specific_package')
      #   # Will link `specific_package` in `"name": "specific_package"`
      #
      #   link_json('name', /[^\/]+\/[^\/]+/)
      #   # Will link `user/repo` in `"name": "user/repo"`, but not `"name": "package"`
      #
      #   link_json('specific_package', '1.0.1', link: :key)
      #   # Will link `specific_package` in `"specific_package": "1.0.1"`
      def link_json(key, value = nil, link: :value, &url_proc)
        key = regexp_for_value(key, default: /[^" ]+/)
        value = regexp_for_value(value, default: /[^" ]+/)

        if link == :value
          value = /(?<name>#{value})/
        else
          key = /(?<name>#{key})/
        end

        link_regex(/"#{key}":\s*"#{value}"/, &url_proc)
      end

      def json
        @json ||= begin
          Gitlab::Json.parse(plain_text)
        rescue StandardError
          nil
        end
      end
    end
  end
end
