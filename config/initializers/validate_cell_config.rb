# frozen_string_literal: true

return if Gitlab::Utils.to_boolean(ENV['SKIP_CELL_CONFIG_VALIDATION'], default: false)

ValidationError = Class.new(StandardError)

if Gitlab.config.cell.id.present? && !Gitlab.config.cell.topology_service.enabled
  raise ValidationError, "Topology Service is not configured, but Cell ID is set"
end

if Gitlab.config.cell.topology_service.enabled && Gitlab.config.cell.id.blank?
  raise ValidationError, "Topology Service is enabled, but Cell ID is not set"
end
