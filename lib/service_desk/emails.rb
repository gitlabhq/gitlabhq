# frozen_string_literal: true

# This class handles the generation and management of various email addresses
# used by the Service Desk feature, including system-generated addresses,
# custom addresses, and alias addresses.
module ServiceDesk
  class Emails
    def initialize(project)
      @project = project
    end

    def all_addresses
      [
        incoming_address,
        alias_address,
        custom_address
      ].compact
    end

    def address
      custom_address || system_address
    end

    def system_address
      alias_address || incoming_address
    end

    def alias_address
      return unless Gitlab::Email::ServiceDeskEmail.enabled?

      key = service_desk_setting&.project_key || default_service_desk_suffix

      Gitlab::Email::ServiceDeskEmail.address_for_key("#{project.full_path_slug}-#{key}")
    end

    def incoming_address
      return unless ServiceDesk.enabled?(project)

      config = Gitlab.config.incoming_email
      wildcard = Gitlab::Email::Common::WILDCARD_PLACEHOLDER

      config.address&.gsub(wildcard, default_subaddress_part)
    end

    def default_subaddress_part
      "#{project.full_path_slug}-#{default_service_desk_suffix}"
    end

    private

    attr_reader :project

    def service_desk_setting
      @service_desk_setting ||= project.service_desk_setting
    end

    def custom_address
      return unless service_desk_setting&.custom_email_enabled?

      service_desk_setting.custom_email
    end

    def default_service_desk_suffix
      "#{project.id}-issue-"
    end
  end
end
