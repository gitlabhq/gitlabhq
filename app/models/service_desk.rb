# frozen_string_literal: true

module ServiceDesk
  def self.table_name_prefix
    'service_desk_'
  end

  def self.enabled?(project)
    supported? && project.service_desk_enabled
  end

  def self.supported?
    ::Gitlab::Email::IncomingEmail.enabled? &&
      ::Gitlab::Email::IncomingEmail.supports_wildcard?
  end
end
