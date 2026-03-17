# frozen_string_literal: true

module Banzai
  module Filter
    module Concerns
      # Common functionality used by filters that interact with diagram services:
      # check settings, find relevant tags in the DOM.
      module DiagramService
        extend ActiveSupport::Concern

        def settings
          Gitlab::CurrentSettings.current_application_settings
        end

        def css_selector_for_code_blocks(lang:)
          %(pre[data-canonical-lang="#{lang}"] > code,
            pre > code[data-canonical-lang="#{lang}"])
        end

        def lang_from_code_block(node)
          node.parent['data-canonical-lang'] || node['data-canonical-lang']
        end
      end
    end
  end
end
