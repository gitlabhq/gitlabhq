# frozen_string_literal: true

module QA
  module Page
    module Group
      class DependencyProxy < QA::Page::Base
        view 'app/assets/javascripts/packages_and_registries/dependency_proxy/app.vue' do
          element :dependency_proxy_count
        end

        def has_blob_count?(blob_text)
          has_element?(:dependency_proxy_count, text: blob_text)
        end
      end
    end
  end
end
