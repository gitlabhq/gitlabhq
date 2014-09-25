module Files
  class BaseService < ::BaseService
    attr_reader :ref, :path

    def initialize(project, user, params, ref, path = nil)
      @project, @current_user, @params = project, user, params.dup
      @ref = ref
      @path = path
    end

    private

    def permission_check
      allowed = if project.protected_branch?(ref)
                  can?(current_user, :push_code_to_protected_branches, project)
                else
                  can?(current_user, :push_code, project)
                end

      unless allowed
        return error('You are not allowed to create file in this branch')
      end

      unless repository.branch_names.include?(ref)
        return error('You can only create files if you are on top of a branch')
      end

      nil
    end

    def text_check
      unless blob
        return error('You can only edit text files')
      end

      nil
    end

    def get_execute_output(ok, msg = '')
      if ok
        success
      else
        error('Your changes could not be committed, '\
              'maybe the file was changed by another process' + msg)
      end
    end

    def blob
      repository.blob_at_branch(ref, path)
    end

    def repository
      project.repository
    end
  end
end
