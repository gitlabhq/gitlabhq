module Ci
  class VariablePresenter < Gitlab::View::Presenter::Delegated
    presents :variable

    def placeholder
      'PROJECT_VARIABLE'
    end

    def form_path
      if variable.persisted?
        namespace_project_variable_path(project.namespace, project, variable)
      else
        namespace_project_variables_path(project.namespace, project)
      end
    end

    def edit_path
      project_variable_path(project, variable)
    end

    def delete_path
      project_variable_path(project, variable)
    end
  end
end
