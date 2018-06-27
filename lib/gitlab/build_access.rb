module Gitlab
  class BuildAccess < UserAccess
    attr_accessor :user, :project

    # This bypasses the `can?(:access_git)`-check we normally do in `UserAccess`
    # for CI. That way if a user was able to trigger a pipeline, then the
    # build is allowed to clone the project.
    def can_access_git?
      true
    end
  end
end
