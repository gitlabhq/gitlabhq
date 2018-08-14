module QA
  module Page
    module Layout
      class Banner < Page::Base
        view 'app/views/layouts/header/_read_only_banner.html.haml' do
          element :flash_notice, ".flash-notice"
        end

        def has_notice?(message)
          page.within('.flash-notice') do
            !!find('span', text: message)
          end
        end
      end
    end
  end
end
