module Gitlab
  module Git
    module Conflict
      class Resolution
        attr_reader :user, :files, :commit_message

        def initialize(user, files, commit_message)
          @user = user
          @files = files
          @commit_message = commit_message
        end
      end
    end
  end
end
