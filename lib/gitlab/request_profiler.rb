# frozen_string_literal: true

require 'fileutils'

module Gitlab
  module RequestProfiler
    PROFILES_DIR = "#{Gitlab.config.shared.path}/tmp/requests_profiles"

    def all
      Dir["#{PROFILES_DIR}/*.{html,txt}"].map do |path|
        Profile.new(File.basename(path))
      end.select(&:valid?)
    end
    module_function :all # rubocop: disable Style/AccessModifierDeclarations

    def find(name)
      file_path = File.join(PROFILES_DIR, name)
      return unless File.exist?(file_path)

      Profile.new(name)
    end
    module_function :find # rubocop: disable Style/AccessModifierDeclarations

    def profile_token
      Rails.cache.fetch('profile-token') do
        Devise.friendly_token
      end
    end
    module_function :profile_token # rubocop: disable Style/AccessModifierDeclarations

    def remove_all_profiles
      FileUtils.rm_rf(PROFILES_DIR)
    end
    module_function :remove_all_profiles # rubocop: disable Style/AccessModifierDeclarations
  end
end
