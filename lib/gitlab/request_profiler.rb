# frozen_string_literal: true

require 'fileutils'

module Gitlab
  module RequestProfiler
    PROFILES_DIR = "#{Gitlab.config.shared.path}/tmp/requests_profiles".freeze

    def all
      Dir["#{PROFILES_DIR}/*.{html,txt}"].map do |path|
        Profile.new(File.basename(path))
      end.select(&:valid?)
    end
    module_function :all

    def find(name)
      file_path = File.join(PROFILES_DIR, name)
      return unless File.exist?(file_path)

      Profile.new(name)
    end
    module_function :find

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
