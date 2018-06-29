module QA
  module Factory
    module Resource
      class MergeRequestFromFork < MergeRequest
        attr_accessor :fork_branch

        dependency Factory::Resource::Fork, as: :fork

        dependency Factory::Repository::ProjectPush, as: :push do |push, factory|
          push.project = factory.fork
          push.branch_name = factory.fork_branch
          push.file_name = 'file2.txt'
          push.user = factory.fork.user
        end

        def fabricate!
          fork.visit!
          Page::Project::Show.act { new_merge_request }
          Page::MergeRequest::New.act { create_merge_request }
        end
      end
    end
  end
end
