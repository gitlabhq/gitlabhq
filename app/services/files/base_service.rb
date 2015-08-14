module Files
  class BaseService < ::BaseService
    attr_reader :ref, :path

    def initialize(project, user, params, ref, path = nil)
      @project, @current_user, @params = project, user, params.dup
      @ref = ref
      @path = path
    end

    private

    def repository
      project.repository
    end
  end
end
