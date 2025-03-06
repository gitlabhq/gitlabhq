# frozen_string_literal: true

return if Gitlab::Utils.to_boolean(ENV['SKIP_CELL_CONFIG_VALIDATION'], default: false)

ValidationError = Class.new(StandardError)

if Gitlab.config.cell.enabled
  raise ValidationError, "Cell ID is not set to a valid positive integer" if Gitlab.config.cell.id.to_i < 1

  Settings.topology_service_settings.each do |setting|
    setting_value = Gitlab.config.cell.topology_service_client.send(setting)
    raise ValidationError, "Topology Service setting '#{setting}' is not set" if setting_value.blank?
  end
elsif Gitlab.config.cell.id.present?
  raise ValidationError, "Cell ID is set but Cell is not enabled"
end
