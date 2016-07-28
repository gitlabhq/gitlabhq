require 'fileutils'

module Gitlab
  module RequestProfiler
    PROFILES_DIR = "#{Gitlab.config.shared.path}/tmp/requests_profiles"

    def profile_token
      Rails.cache.fetch('profile-token') do
        Devise.friendly_token
      end
    end
    module_function :profile_token

    def remove_all_profiles
      FileUtils.rm_rf(PROFILES_DIR)
    end
    module_function :remove_all_profiles
  end
end
