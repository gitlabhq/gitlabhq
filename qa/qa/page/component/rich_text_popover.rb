# frozen_string_literal: true

module QA
  module Page
    module Component
      module RichTextPopover
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/assets/javascripts/vue_shared/components/markdown/editor_mode_switcher.vue' do
            element :rich_text_promo_popover
          end

          base.view 'app/views/shared/_broadcast_message.html.haml' do
            element :close_button
          end
        end

        def close_rich_text_promo_popover_if_present
          return unless has_element?(:rich_text_promo_popover, wait: 0)

          within_element(:rich_text_promo_popover) do
            click_element(:close_button)
          end
          has_no_element?(:rich_text_promo_popover)
        end
      end
    end
  end
end
