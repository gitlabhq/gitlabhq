# == Schema Information
#
# Table name: application_settings
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
    
    def self.current
      Ci::ApplicationSetting.last
    end

    def self.create_from_defaults
      create(
        all_broken_builds: Settings.gitlab_ci['all_broken_builds'],
        add_pusher: Settings.gitlab_ci['add_pusher'],
      )
    end
  end
end
