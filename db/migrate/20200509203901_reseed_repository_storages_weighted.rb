# frozen_string_literal: true

class ReseedRepositoryStoragesWeighted < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  class ApplicationSetting < ActiveRecord::Base
    serialize :repository_storages
    self.table_name = 'application_settings'
  end

  def up
    reseed_repository_storages_weighted
  end

  private

  def reseed_repository_storages_weighted
    # We need to flush the cache to ensure the newly-added column is loaded
    ApplicationSetting.reset_column_information

    # There should only be one row here due to
    # 20200420162730_remove_additional_application_settings_rows.rb
    ApplicationSetting.all.each do |settings|
      # Admins may have already tweaked these values, so don't do anything
      # if there is data already.
      next if settings.repository_storages_weighted.present?

      storages = Gitlab.config.repositories.storages.keys.collect do |storage|
        weight = settings.repository_storages.include?(storage) ? 100 : 0
        [storage.to_sym, weight]
      end

      settings.repository_storages_weighted = Hash[storages]
      settings.save!
    end
  end
end
