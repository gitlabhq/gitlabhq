# frozen_string_literal: true

module QA
  module Page
    module Alert
      class AutoDevopsAlert < Page::Base
        view 'app/views/shared/_auto_devops_implicitly_enabled_banner.html.haml' do
          element :auto_devops_banner
        end
      end
    end
  end
end
