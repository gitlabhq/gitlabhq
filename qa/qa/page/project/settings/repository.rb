module QA
  module Page
    module Project
      module Settings
        class Repository < Page::Base
          def expand(title)
            page.within('#content-body') do
              find('.qa-expand-deploy-keys').click
            end
          end
        end
      end
    end
  end
end
