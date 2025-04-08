# frozen_string_literal: true

return if Gitlab::Utils.to_boolean(ENV['SKIP_CELL_CONFIG_VALIDATION'], default: false)

ValidationError = Class.new(StandardError)

print_error = ->(error_message) do
  message = error_message
  message += <<~MESSAGE if Gitlab.dev_or_test_env?

    Make sure your development environment is up to date.
    For example, on GDK, run: gdk update
  MESSAGE

  raise ValidationError, message
end

if Gitlab.config.cell.enabled
  print_error.call("Cell ID is not set to a valid positive integer.") if Gitlab.config.cell.id.to_i < 1

  Settings.required_topology_service_settings.each do |setting|
    setting_value = Gitlab.config.cell.topology_service_client.send(setting)
    print_error.call("Topology Service setting '#{setting}' is not set.") if setting_value.blank?
  end
elsif Gitlab.config.cell.id.present?
  print_error.call("Cell ID is set but Cell is not enabled.")
end
