# frozen_string_literal: true

module QA
  module Page
    module Layout
      class Banner < Page::Base
        view 'app/views/layouts/header/_read_only_banner.html.haml' do
          element 'read-only-banner'
        end

        def has_notice?(message)
          page.within('.gl-alert') do
            !!find('.gl-alert-body', text: message)
          end
        end
      end
    end
  end
end
