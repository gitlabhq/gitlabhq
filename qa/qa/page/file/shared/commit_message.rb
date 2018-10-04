module QA
  module Page
    module File
      module Shared
        module CommitMessage
          def self.included(base)
            base.view 'app/views/shared/_commit_message_container.html.haml' do
              element :commit_message, "text_area_tag 'commit_message'"
            end
          end

          def add_commit_message(message)
            fill_in 'commit_message', with: message
          end
        end
      end
    end
  end
end
