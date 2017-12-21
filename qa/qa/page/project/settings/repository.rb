module QA
  module Page
    module Project
      module Settings
        class Repository < Page::Base
          def expand(title)
            page.within('#content-body') do
              find(
                :xpath,
                "//button[contains(text(), 'Expand')]" +
                  "[../h4[contains(text(), '#{title}')]]"
              ).click
            end
          end
        end
      end
    end
  end
end
