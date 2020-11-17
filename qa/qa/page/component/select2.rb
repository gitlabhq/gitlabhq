# frozen_string_literal: true

module QA
  module Page
    module Component
      module Select2
        def select_item(item_text)
          find('.select2-result-label', text: item_text, match: :prefer_exact).click
        end

        def has_item?(item_text)
          has_css?('.select2-result-label', text: item_text, match: :prefer_exact)
        end

        def current_selection
          find('.select2-chosen').text
        end

        def clear_current_selection_if_present
          if has_css?('a > abbr.select2-search-choice-close', wait: 1.0)
            find('a > abbr.select2-search-choice-close').click
          end
        end

        def search_item(item_text)
          find('.select2-input').set(item_text)

          wait_for_search_to_complete
        end

        def search_and_select(item_text)
          QA::Runtime::Logger.info "Searching and selecting: #{item_text}"

          search_item(item_text)

          raise QA::Page::Base::ElementNotFound, %Q(Couldn't find option named "#{item_text}") unless has_item?(item_text)

          select_item(item_text)
        end

        def search_and_select_exact(item_text)
          QA::Runtime::Logger.info "Searching and selecting: #{item_text}"

          search_item(item_text)

          raise QA::Page::Base::ElementNotFound, %Q(Couldn't find option named "#{item_text}") unless has_item?(item_text)

          find('.select2-result-label', text: item_text, exact_text: true).click
        end

        def expand_select_list
          find('span.select2-arrow').click
        end

        def wait_for_search_to_complete
          Support::WaitForRequests.wait_for_requests

          has_css?('.select2-active', wait: 1)
          has_no_css?('.select2-active', wait: 30)
        end

        def dropdown_open?
          find('.select2-focusser').disabled?
        end
      end
    end
  end
end
