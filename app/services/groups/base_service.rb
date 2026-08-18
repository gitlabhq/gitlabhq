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

    def handle_crm_settings_update
      return if params[:crm_enabled].nil? && params[:crm_source_group_id].nil?

      crm_enabled = params.delete(:crm_enabled)
      crm_enabled = true if crm_enabled.nil?
      crm_source_group_id = params.delete(:crm_source_group_id).presence&.to_i
      return if group.crm_enabled? == crm_enabled && group.crm_settings&.source_group_id == crm_source_group_id

      if group.crm_settings&.source_group_id != crm_source_group_id && group.has_issues_with_contacts?
        message = s_('GroupSettings|Contact source cannot be changed when issues already ' \
          'have contacts assigned from a different source.')
        group.errors.add(:base, message)
        return
      end

      crm_settings = group.crm_settings || group.build_crm_settings
      crm_settings.enabled = crm_enabled
      crm_settings.source_group_id = crm_source_group_id
      crm_settings.save
    end

    def remove_unallowed_params
      # overridden in EE
    end

    def service_desk_address_conflict_message(project_full_path)
      format(
        s_('GroupSettings|Service Desk address for project %{project_path} is already in use. ' \
          'Change the Service Desk project key before moving or renaming this group.'),
        project_path: project_full_path
      )
    end
  end
end
