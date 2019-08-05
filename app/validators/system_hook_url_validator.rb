# frozen_string_literal: true

# SystemHookUrlValidator
#
# Custom validator specific to SystemHook URLs. This validator works like AddressableUrlValidator but
# it blocks urls pointing to localhost or the local network depending on
# ApplicationSetting.allow_local_requests_from_system_hooks
#
# Example:
#   class SystemHook < WebHook
#     validates :url, system_hook_url: true
#   end
#
class SystemHookUrlValidator < PublicUrlValidator
  def self.allow_setting_local_requests?
    ApplicationSetting.current&.allow_local_requests_from_system_hooks?
  end
end
