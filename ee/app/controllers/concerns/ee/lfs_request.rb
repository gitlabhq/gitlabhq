module EE
  module LfsRequest
    extend ActiveSupport::Concern

    def lfs_forbidden!
      if project.above_size_limit? || objects_exceed_repo_limit?
        render_size_error
      else
        super
      end
    end

    def render_size_error
      render(
        json: {
          message: ::Gitlab::RepositorySizeError.new(project).push_error(@exceeded_limit),
          documentation_url: help_url
        },
        content_type: "application/vnd.git-lfs+json",
        status: 406
      )
    end

    def objects_exceed_repo_limit?
      return false unless project.size_limit_enabled?
      return @limit_exceeded if defined?(@limit_exceeded)

      lfs_push_size = objects.sum { |o| o[:size] }
      size_with_lfs_push = project.repository_and_lfs_size + lfs_push_size

      @exceeded_limit = size_with_lfs_push - project.actual_size_limit
      @limit_exceeded = @exceeded_limit > 0
    end
  end
end
