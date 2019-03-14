module QA
  module Page
    module Component
      module Select2
        def select_item(item_text)
          find('.select2-result-label', text: item_text, match: :prefer_exact).click
        end

        def clear_current_selection_if_present
          if has_css?('a > abbr.select2-search-choice-close', wait: 1.0)
            find('a > abbr.select2-search-choice-close').click
          end
        end

        def search_and_select(item_text)
          find('.select2-input').set(item_text)
          select_item(item_text)
        end
      end
    end
  end
end
