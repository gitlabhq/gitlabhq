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
            end
          end
        end
      end
    end
  end
end
