module Ci
  class GroupVariablePresenter < Gitlab::View::Presenter::Delegated
    presents :variable

    def placeholder
      'GROUP_VARIABLE'
    end

    def form_path
      if variable.persisted?
        group_variable_path(group, variable)
      else
        group_variables_path(group)
      end
    end

    def edit_path
      group_variable_path(group, variable)
    end

    def delete_path
      group_variable_path(group, variable)
    end
  end
end
