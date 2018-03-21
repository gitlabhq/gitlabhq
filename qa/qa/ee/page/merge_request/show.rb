module QA
  module EE
    module Page
      module MergeRequest
        module Show
          def self.prepended(page)
            page.module_eval do
              view 'app/assets/javascripts/vue_merge_request_widget/components/states/sha_mismatch.vue' do
                element :head_mismatch, "The source branch HEAD has recently changed."
              end

              view 'ee/app/assets/javascripts/vue_merge_request_widget/components/states/mr_widget_squash_before_merge.js' do
                element :squash_checkbox
              end
            end
          end

          def mark_to_squash
            wait(reload: true) do
              has_css?(element_selector_css(:squash_checkbox))
            end

            click_element :squash_checkbox
          end
        end
      end
    end
  end
end
