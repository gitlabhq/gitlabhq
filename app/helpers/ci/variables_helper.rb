# frozen_string_literal: true

module Ci
  module VariablesHelper
    def ci_variable_protected_by_default?
      Gitlab::CurrentSettings.current_application_settings.protected_ci_variables
    end

    def create_deploy_token_path(entity, opts = {})
      if entity.is_a?(::Group)
        create_deploy_token_group_settings_repository_path(entity, opts)
      else
        # TODO: change this path to 'create_deploy_token_project_settings_ci_cd_path'
        # See MR comment for more detail: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/27059#note_311585356
        create_deploy_token_project_settings_repository_path(entity, opts)
      end
    end

    def revoke_deploy_token_path(entity, token)
      if entity.is_a?(::Group)
        revoke_group_deploy_token_path(entity, token)
      else
        revoke_project_deploy_token_path(entity, token)
      end
    end

    def ci_variable_maskable_raw_regex
      Ci::Maskable::MASK_AND_RAW_REGEX.inspect.sub('\\A', '^').sub('\\z', '$')[1...-1]
    end

    def ci_variable_maskable_regex
      Ci::Maskable::REGEX.inspect.sub('\\A', '^').sub('\\z', '$').sub(%r{^/}, '').sub(%r{/[a-z]*$}, '').gsub('\/', '/')
    end
  end
end
