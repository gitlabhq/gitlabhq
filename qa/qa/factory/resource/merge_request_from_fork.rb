module QA
  module Factory
    module Resource
      class MergeRequestFromFork < MergeRequest
        dependency Factory::Resource::Fork, as: :fork

        dependency Factory::Repository::ProjectPush, as: :push do |push, factory|
          push.project = factory.fork
          push.file_name = 'file2.txt'
        end

        def fabricate!
          fork.visit!
          Page::Menu::Side.act { click_merge_requests }
          Page::MergeRequest::Index.act { new_merge_request }

          Page::MergeRequest::CompareBeforeNew.act do
            select_source_branch('master')
            compare_branches_and_continue
          end

          Page::MergeRequest::New.act { create_merge_request }
        end
      end
    end
  end
end
