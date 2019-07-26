# frozen_string_literal: true

# SystemHookUrlValidator
#
# Custom validator specifically for SystemHook URLs. This validator works like AddressableUrlValidator but
# it blocks urls pointing to localhost or the local network depending on
# ApplicationSetting.allow_local_requests_from_system_hooks
#
# Example:
#
#   class SystemHook < WebHook
#     validates :url, system_hook_url: { allow_localhost: true, allow_local_network: true }
#   end
#
class SystemHookUrlValidator < AddressableUrlValidator
  DEFAULT_OPTIONS = {
    allow_localhost: true,
    allow_local_network: true
  }.freeze

  def initialize(options)
    options.reverse_merge!(DEFAULT_OPTIONS)

    super(options)
  end

  def self.allow_setting_local_requests?
    ApplicationSetting.current&.allow_local_requests_from_system_hooks?
  end
end
