module Files
  class BaseService < ::BaseService
    attr_reader :ref, :path

    def initialize(project, user, params, ref, path = nil)
      @project, @current_user, @params = project, user, params.dup
      @ref = ref
      @path = path
    end

    private

    def success
      out = super()
      out[:error] = ''
      out
    end

    def repository
      project.repository
    end

    def git_hook
      project.git_hook
    end
  end
end
