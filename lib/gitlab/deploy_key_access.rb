# frozen_string_literal: true

module Gitlab
  class DeployKeyAccess < UserAccess
    def initialize(deploy_key, container: nil)
      @deploy_key = deploy_key
      @user = deploy_key.user
      @container = container
    end

    def can_push_for_ref?(ref)
      can_push_to_branch?(ref)
    end

    private

    attr_reader :deploy_key

    def can_collaborate?(_ref)
      assert_project!

      project_has_active_user_keys?
    end

    def project_has_active_user_keys?
      user.can?(:read_project, project) && DeployKey.with_write_access_for_project(project).id_in(deploy_key.id).exists?
    end
  end
end
