# frozen_string_literal: true

module Groups
  class BaseService < ::BaseService
    attr_accessor :group, :current_user, :params

    def initialize(group, user, params = {})
      @group = group
      @current_user = user
      @params = params.dup
    end

    private

    def handle_namespace_settings
      settings_params = params.slice(*::NamespaceSetting.allowed_namespace_settings_params)

      return if settings_params.empty?

      ::NamespaceSetting.allowed_namespace_settings_params.each do |nsp|
        params.delete(nsp)
      end

      ::NamespaceSettings::AssignAttributesService.new(current_user, group, settings_params).execute
    end

    def remove_unallowed_params
      # overridden in EE
    end

    # This is a temporary shim to address an issue with
    #   https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135959 and should
    #   be removed when the issue is resolved.
    #
    # rubocop:disable Style/IfUnlessModifier -- you're entirely wrong
    # rubocop:disable Style/NegatedIf -- you're entirely wrong
    def invert_emails_disabled_to_emails_enabled
      return unless Feature.enabled?(:invert_emails_disabled_to_emails_enabled)
      return unless params.key?(:emails_disabled)

      if !params[:emails_disabled].nil?
        params[:emails_enabled] = !Gitlab::Utils.to_boolean(params[:emails_disabled])
      end

      params.delete(:emails_disabled)
    end
    # rubocop:enable Style/IfUnlessModifier
    # rubocop:enable Style/NegatedIf
  end
end
