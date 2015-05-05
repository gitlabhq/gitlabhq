require 'html/pipeline/filter'
require 'html/pipeline/sanitization_filter'

module Gitlab
  module Markdown
    # Sanitize HTML
    #
    # Extends HTML::Pipeline::SanitizationFilter with a custom whitelist.
    class SanitizationFilter < HTML::Pipeline::SanitizationFilter
      def whitelist
        whitelist = HTML::Pipeline::SanitizationFilter::WHITELIST

        # Allow `class` and `id` on all elements
        whitelist[:attributes][:all].push('class', 'id')

        # Allow table alignment
        whitelist[:attributes]['th'] = %w(style)
        whitelist[:attributes]['td'] = %w(style)

        # Allow span elements
        whitelist[:elements].push('span')

        # Remove `rel` attribute from `a` elements
        whitelist[:transformers].push(remove_rel)

        whitelist
      end

      def remove_rel
        lambda do |env|
          if env[:node_name] == 'a'
            env[:node].remove_attribute('rel')
          end
        end
      end
    end
  end
end
