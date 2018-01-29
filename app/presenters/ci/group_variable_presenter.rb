module Ci
  class GroupVariablePresenter < Gitlab::View::Presenter::Delegated
    presents :variable

    def placeholder
      'GROUP_VARIABLE'
    end

    def form_path
      group_settings_ci_cd_path(group)
    end

    def edit_path
      group_variables_path(group)
    end

    def delete_path
      group_variables_path(group)
    end
  end
end
