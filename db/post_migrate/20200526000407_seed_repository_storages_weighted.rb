# frozen_string_literal: true

class SeedRepositoryStoragesWeighted < ActiveRecord::Migration[6.0]
  class ApplicationSetting < ActiveRecord::Base
    serialize :repository_storages
    self.table_name = 'application_settings'
  end

  def up
    ApplicationSetting.all.each do |settings|
      storages = Gitlab.config.repositories.storages.keys.collect do |storage|
        weight = settings.repository_storages.include?(storage) ? 100 : 0
        [storage, weight]
      end

      settings.repository_storages_weighted = Hash[storages]
      settings.save!
    end
  end

  def down
  end
end
