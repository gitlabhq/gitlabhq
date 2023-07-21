# frozen_string_literal: true

module QA
  module Page
    module Group
      class DependencyProxy < QA::Page::Base
        view 'app/assets/javascripts/packages_and_registries/dependency_proxy/app.vue' do
          element :proxy_count
        end

        def has_blob_count?(blob_text)
          has_element?(:proxy_count, text: blob_text)
        end
      end
    end
  end
end
