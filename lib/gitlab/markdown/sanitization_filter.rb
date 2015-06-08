require 'html/pipeline/filter'
require 'html/pipeline/sanitization_filter'

module Gitlab
  module Markdown
    # Sanitize HTML
    #
    # Extends HTML::Pipeline::SanitizationFilter with a custom whitelist.
    class SanitizationFilter < HTML::Pipeline::SanitizationFilter
      def whitelist
        # Descriptions are more heavily sanitized, allowing only a few elements.
        # See http://git.io/vkuAN
        if pipeline == :description
          whitelist = LIMITED
          whitelist[:elements] -= %w(pre code img ol ul li)
        else
          whitelist = super
        end

        customize_whitelist(whitelist)

        whitelist
      end

      private

      def pipeline
        context[:pipeline] || :default
      end

      def customized?(transformers)
        transformers.last.source_location[0] == __FILE__
      end

      def customize_whitelist(whitelist)
        # Only push these customizations once
        return if customized?(whitelist[:transformers])

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
