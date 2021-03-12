# frozen_string_literal: true

module Gitlab
  module Usage
    module Docs
      class ValueFormatter
        def self.format(key, value)
          return '' unless value.present?

          case key
          when :key_path
            "**`#{value}`**"
          when :data_source
            value.to_s.capitalize
          when :product_group, :product_category, :status
            "`#{value}`"
          when :introduced_by_url
            "[Introduced by](#{value})"
          when :distribution, :tier
            Array(value).map { |tier| " `#{tier}`" }.join(',')
          else
            value
          end
        end
      end
    end
  end
end
