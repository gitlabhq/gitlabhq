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

        # Allow code highlighting
        whitelist[:attributes]['pre'] = %w(class)
        whitelist[:attributes]['span'] = %w(class)

        # Allow table alignment
        whitelist[:attributes]['th'] = %w(style)
        whitelist[:attributes]['td'] = %w(style)

        # Allow span elements
        whitelist[:elements].push('span')

        # Remove `rel` attribute from `a` elements
        whitelist[:transformers].push(remove_rel)

        # Remove `class` attribute from non-highlight spans
        whitelist[:transformers].push(clean_spans)

        whitelist
      end

      def remove_rel
        lambda do |env|
          if env[:node_name] == 'a'
            env[:node].remove_attribute('rel')
          end
        end
      end

      def clean_spans
        lambda do |env|
          return unless env[:node_name] == 'span'
          return unless env[:node].has_attribute?('class')

          unless has_ancestor?(env[:node], 'pre')
            env[:node].remove_attribute('class')
          end
        end
      end
    end
  end
end
