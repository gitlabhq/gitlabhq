# frozen_string_literal: true

module QA
  module Page
    module Component
      module Dropdown
        include Select2

        def select_item(item_text)
          return super if use_select2?

          find('li.gl-dropdown-item', text: item_text, match: :prefer_exact).click
        end

        def has_item?(item_text)
          return super if use_select2?

          has_css?('li.gl-dropdown-item', text: item_text, match: :prefer_exact)
        end

        def current_selection
          return super if use_select2?

          expand_select_list unless dropdown_open?
          find('span.gl-dropdown-button-text').text
        end

        def all_items
          raise NotImplementedError if use_select2?

          find_all("li.gl-dropdown-item").map(&:text)
        end

        def clear_current_selection_if_present
          return super if use_select2?

          expand_select_list unless dropdown_open?

          if has_css?('button[data-testid="listbox-reset-button"]')
            find('button[data-testid="listbox-reset-button"]').click
          elsif dropdown_open?
            expand_select_list
          end
        end

        def search_item(item_text)
          return super if use_select2?

          find('div.gl-listbox-search input[type="Search"]').set(item_text)
          wait_for_search_to_complete
        end

        def search_and_select(item_text)
          return super if use_select2?

          QA::Runtime::Logger.info "Searching and selecting: #{item_text}"

          search_item(item_text)

          unless has_item?(item_text)
            raise QA::Page::Base::ElementNotFound, %(Couldn't find option named "#{item_text}")
          end

          select_item(item_text)
        end

        def search_and_select_exact(item_text)
          return super if use_select2?

          QA::Runtime::Logger.info "Searching and selecting: #{item_text}"

          search_item(item_text)

          unless has_item?(item_text)
            raise QA::Page::Base::ElementNotFound, %(Couldn't find option named "#{item_text}")
          end

          find('li.gl-dropdown-item span:nth-child(2)', text: item_text, exact_text: true).click
        end

        def expand_select_list
          return super if use_select2?

          find('svg.dropdown-chevron').click
        end

        def wait_for_search_to_complete
          return super if use_select2?

          Support::WaitForRequests.wait_for_requests

          has_css?('div[data-testid="listbox-search-loader"]', wait: 1)
          has_no_css?('div[data-testid="listbox-search-loader"]')
        end

        def dropdown_open?
          return super if use_select2?

          has_css?('ul.gl-dropdown-contents', wait: 1)
        end

        def find_input_by_prefix_and_set(element_prefix, item_text)
          find("input[id^=\"#{element_prefix}\"]").set(item_text)
        end

        private

        # rubocop:disable Gitlab/PredicateMemoization
        def use_select2?
          @use_select2 ||= has_css?('.select2-container', wait: 1)
        end
        # rubocop:enable Gitlab/PredicateMemoization
      end
    end
  end
end
