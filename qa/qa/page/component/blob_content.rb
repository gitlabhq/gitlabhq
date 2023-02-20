# frozen_string_literal: true

module QA
  module Page
    module Component
      module BlobContent
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/assets/javascripts/blob/components/blob_header_filepath.vue' do
            element :file_title_content
          end

          base.view 'app/assets/javascripts/blob/components/blob_content.vue' do
            element :blob_viewer_file_content
          end

          base.view 'app/assets/javascripts/blob/components/blob_header_default_actions.vue' do
            element :default_actions_container
            element :copy_contents_button
          end

          base.view 'app/assets/javascripts/vue_shared/components/source_viewer/source_viewer_deprecated.vue' do
            element :blob_viewer_file_content
          end
        end

        def has_file?(name)
          has_file_name?(name)
        end

        def has_no_file?(name)
          has_no_file_name?(name)
        end

        def has_file_name?(file_name, file_number = nil)
          within_file_by_number(:file_title_content, file_number) { has_text?(file_name) }
        end

        def has_no_file_name?(file_name)
          within_element(:file_title_content) do
            has_no_text?(file_name)
          end
        end

        def has_file_content?(file_content, file_number = nil)
          within_file_by_number(:blob_viewer_file_content, file_number) { has_text?(file_content) }
        end

        def has_no_file_content?(file_content)
          within_element(:blob_viewer_file_content) do
            has_no_text?(file_content)
          end
        end

        def has_normalized_ws_text?(text, wait: Capybara.default_max_wait_time)
          if has_element?(:blob_viewer_file_content, wait: 1)
            # The blob viewer renders line numbers and whitespace in a way that doesn't match the source file
            # This isn't a visual validation test, so we ignore line numbers and whitespace
            find_element(:blob_viewer_file_content, wait: 0).text.gsub(/^\d+\s|\s*/, '')
              .start_with?(text.gsub(/\s*/, ''))
          else
            has_text?(text.gsub(/\s+/, " "), wait: wait)
          end
        end

        def click_copy_file_contents(file_number = nil)
          within_file_by_number(:default_actions_container, file_number) { click_element(:copy_contents_button) }
        end

        private

        def within_file_by_number(element, file_number, &block)
          if file_number
            within_element_by_index(element, file_number - 1, &block)
          else
            within_element(element, &block)
          end
        end
      end
    end
  end
end
