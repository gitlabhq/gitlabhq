# frozen_string_literal: true

module Gitlab
  module Usage
    module Docs
      class ValueFormatter
        def self.format(key, value)
          case key
          when :key_path
            "**#{value}**"
          when :data_source
            value.capitalize
          when :group
            "`#{value}`"
          when :introduced_by_url
            "[Introduced by](#{value})"
          when :distribution, :tier
            Array(value).join(', ')
          else
            value
          end
        end
      end
    end
  end
end
