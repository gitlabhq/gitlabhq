# frozen_string_literal: true

module QA
  module Page
    module Project
      module Release
        class Show < Page::Base
          view 'app/assets/javascripts/releases/components/release_block_title.vue' do
            element 'release-name'
          end

          view 'app/assets/javascripts/releases/components/release_block.vue' do
            element 'release-description'
          end

          view 'app/assets/javascripts/releases/components/release_block_milestone_info.vue' do
            element 'milestone-title'
          end

          view 'app/assets/javascripts/releases/components/release_block_assets.vue' do
            element 'asset-link'
          end

          def has_release_name?(name)
            has_element?('release-name', text: name)
          end

          def has_release_description?(description)
            has_element?('release-description', text: description)
          end

          def has_milestone_title?(title)
            has_element?('milestone-title', text: title)
          end

          def has_asset_link?(name, path)
            element = find_element('asset-link', text: name)

            element["href"].include?(path)
          end
        end
      end
    end
  end
end
