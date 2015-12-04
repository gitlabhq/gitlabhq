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
    CACHE_KEY = 'ci_application_setting.last'

    after_commit do
      Rails.cache.write(CACHE_KEY, self)
    end

    def self.expire
      Rails.cache.delete(CACHE_KEY)
    end

    def self.current
      Rails.cache.fetch(CACHE_KEY) do
        Ci::ApplicationSetting.last
      end
    end

    def self.create_from_defaults
      create(
        all_broken_builds: Settings.gitlab_ci['all_broken_builds'],
        add_pusher: Settings.gitlab_ci['add_pusher'],
      )
    end
  end
end
