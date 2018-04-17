module QA
  module Page
    module MergeRequest
      class Show < Page::Base
<<<<<<< HEAD
        prepend QA::EE::Page::MergeRequest::Show

=======
>>>>>>> upstream/master
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

        def rebase!
          click_element :mr_rebase_button

          wait(reload: false) do
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
          click_element :merge_button

          wait(reload: false) do
            has_text?('The changes were merged into')
          end
        end
      end
    end
  end
end
