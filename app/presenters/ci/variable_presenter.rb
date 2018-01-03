module Ci
  class VariablePresenter < Gitlab::View::Presenter::Delegated
    presents :variable

    def placeholder
      'PROJECT_VARIABLE'
    end

    def form_path
      if variable.persisted?
        project_variable_path(project, variable)
      else
        project_variables_path(project)
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
