# frozen_string_literal: true

# In order to measure and log execution of our service, we just need to 'prepend Measurable' module
# Example:
# ```
#   class DummyService
#     def execute
#       # ...
#     end
#   end

#   DummyService.prepend(Measurable)
# ```
#
# In case when we are prepending a module from the `EE` namespace with EE features
# we need to prepend Measurable after prepending `EE` module.
# This way Measurable will be at the bottom of the ancestor chain,
# in order to measure execution of `EE` features as well
# ```
#   class DummyService
#     def execute
#       # ...
#     end
#   end
#
#   DummyService.prepend_mod_with('DummyService')
#   DummyService.prepend(Measurable)
# ```
#
module Measurable
  extend ::Gitlab::Utils::Override

  override :execute
  def execute(*args)
    measuring? ? ::Gitlab::Utils::Measuring.new(base_log_data).with_measuring { super(*args) } : super(*args)
  end

  protected

  # You can set extra attributes for performance measurement log.
  def extra_attributes_for_measurement
    defined?(super) ? super : {}
  end

  private

  def measuring?
    Feature.enabled?("gitlab_service_measuring_#{service_class}", type: :ops)
  end

  # These attributes are always present in log.
  def base_log_data
    extra_attributes_for_measurement.merge({ class: self.class.name })
  end

  def service_class
    self.class.name.underscore.tr('/', '_')
  end
end
