# frozen_string_literal: true

module Gitlab
  class GitAccessDesign < GitAccess
    extend ::Gitlab::Utils::Override

    # TODO Re-factor so that correct container is passed to the constructor
    # and this method can be removed from here
    # https://gitlab.com/gitlab-org/gitlab/-/issues/409454
    def initialize(
      actor, container, protocol, authentication_abilities:, repository_path: nil, redirected_path: nil,
      auth_result_type: nil)
      super(
        actor,
        select_container(container),
        protocol,
        authentication_abilities: authentication_abilities,
        repository_path: repository_path,
        redirected_path: redirected_path,
        auth_result_type: auth_result_type
      )
    end

    def check(_cmd, _changes)
      check_protocol!
      check_can_create_design!

      success_result
    end

    override :push_ability
    def push_ability
      :create_design
    end

    private

    def select_container(container)
      container.is_a?(::DesignManagement::Repository) ? container.project : container
    end

    def check_protocol!
      if protocol != 'web'
        raise ::Gitlab::GitAccess::ForbiddenError, "Designs are only accessible using the web interface"
      end
    end

    def check_can_create_design!
      unless user_can_push?
        raise ::Gitlab::GitAccess::ForbiddenError, "You are not allowed to manage designs of this project"
      end
    end
  end
end

Gitlab::GitAccessDesign.prepend_mod_with('Gitlab::GitAccessDesign')
