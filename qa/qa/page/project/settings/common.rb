module QA
  module Page
    module Project
      module Settings
        module Common
          def expand(selector)
            page.within('#content-body') do
              find(selector).click

              yield
            end
          end
        end
      end
    end
  end
end
