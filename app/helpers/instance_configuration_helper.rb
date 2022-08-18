# frozen_string_literal: true

module InstanceConfigurationHelper
  def instance_configuration_cell_html(value, &block)
    return '-' unless value.to_s.presence

    block ? yield(value) : value
  end

  def instance_configuration_host(host)
    @instance_configuration_host ||= instance_configuration_cell_html(host).capitalize
  end

  # Value must be in bytes
  def instance_configuration_human_size_cell(value)
    instance_configuration_cell_html(value) do |v|
      number_to_human_size(v, strip_insignificant_zeros: true, significant: false)
    end
  end

  def instance_configuration_disabled_cell_html(value)
    instance_configuration_cell_html(value == 0 ? nil : value)
  end
end
