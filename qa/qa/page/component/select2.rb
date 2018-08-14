module QA
  module Page
    module Component
      module Select2
        def select_item(item_text)
          find('ul.select2-result-sub > li', text: item_text).click
        end
      end
    end
  end
end
