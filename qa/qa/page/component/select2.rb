module QA
  module Page
    module Component
      module Select2
        def select_item(item_text)
          find('.select2-result-label', text: item_text).click
        end

        def search_and_select(item_text)
          find('.select2-input').set(item_text)
          select_item(item_text)
        end
      end
    end
  end
end
