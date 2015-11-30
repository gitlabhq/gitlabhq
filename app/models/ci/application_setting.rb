# == Schema Information
#
# Table name: ci_application_settings
#
#  id                :integer          not null, primary key
#  all_broken_builds :boolean
#  add_pusher        :boolean
#  created_at        :datetime
#  updated_at        :datetime
#

module Ci
  class ApplicationSetting < ActiveRecord::Base
    extend Ci::Model

    after_commit do
      Rails.cache.write(cache_key, self)
    end

    def self.expire
      Rails.cache.delete(cache_key)
    end

    def self.current
      Rails.cache.fetch(cache_key) do
        Ci::ApplicationSetting.last
      end
    end

    def self.create_from_defaults
      create(
        all_broken_builds: Settings.gitlab_ci['all_broken_builds'],
        add_pusher: Settings.gitlab_ci['add_pusher'],
      )
    end

    def self.cache_key
      'ci_application_setting.last'
    end
  end
end
