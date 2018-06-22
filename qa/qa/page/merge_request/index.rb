module QA
  module Page
    module MergeRequest
      class Index < Page::Base
        view 'app/views/projects/merge_requests/_nav_btns.html.haml' do
          element :new_merge_request_link, /link_to new_merge_request_path/
          element :new_merge_request_link_text, "New merge request"
        end

        def new_merge_request
          click_link 'New merge request'
        end
      end
    end
  end
end
