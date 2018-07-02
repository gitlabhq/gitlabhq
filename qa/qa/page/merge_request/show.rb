module QA
  module Page
    module MergeRequest
      class Show < Page::Base
        view 'app/assets/javascripts/vue_merge_request_widget/components/states/ready_to_merge.vue' do
          element :merge_button
          element :fast_forward_message, 'Fast-forward merge without a merge commit'
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/states/mr_widget_merged.vue' do
          element :merged_status, 'The changes were merged into'
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/states/mr_widget_rebase.vue' do
          element :mr_rebase_button
          element :no_fast_forward_message, 'Fast-forward merge is not possible'
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/states/mr_widget_squash_before_merge.vue' do
          element :squash_checkbox
        end

        def rebase!
          # The rebase button is disabled on load
          wait.sleep do
            has_css?(element_selector_css(:mr_rebase_button))
          end

          # The rebase button is enabled via JS
          wait.sleep(reload: false) do
            !first(element_selector_css(:mr_rebase_button)).disabled?
          end

          click_element :mr_rebase_button

          wait.sleep(reload: false) do
            has_text?('Fast-forward merge without a merge commit')
          end
        end

        def fast_forward_possible?
          !has_text?('Fast-forward merge is not possible')
        end

        def has_merge_button?
          refresh

          has_selector?('.accept-merge-request')
        end

        def merge!
          # The merge button is disabled on load
          wait.sleep do
            has_css?(element_selector_css(:merge_button))
          end

          # The merge button is enabled via JS
          wait.sleep(reload: false) do
            !first(element_selector_css(:merge_button)).disabled?
          end

          click_element :merge_button

          wait.sleep(reload: false) do
            has_text?('The changes were merged into')
          end
        end

        def mark_to_squash
          # The squash checkbox is disabled on load
          wait.sleep do
            has_css?(element_selector_css(:squash_checkbox))
          end

          # The squash checkbox is enabled via JS
          wait.sleep(reload: false) do
            !first(element_selector_css(:squash_checkbox)).disabled?
          end

          click_element :squash_checkbox
        end
      end
    end
  end
end
