# frozen_string_literal: true

module QA
  module Page
    module Component
      module ListboxFilter
        def filter_and_select(item)
          page.has_css?('.gl-listbox-search-input', wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME)

          find('.gl-listbox-search-input').set(item)
          find('.gl-new-dropdown-item', text: item, exact_text: true).click
        end
      end
    end
  end
end
