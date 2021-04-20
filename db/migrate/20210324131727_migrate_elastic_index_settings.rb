# frozen_string_literal: true

class MigrateElasticIndexSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  ALIAS_NAME = [Rails.application.class.module_parent_name.downcase, Rails.env].join('-')

  class ElasticIndexSetting < ActiveRecord::Base
  end

  class ApplicationSetting < ActiveRecord::Base
  end

  def up
    setting = ApplicationSetting.first
    number_of_replicas = setting&.elasticsearch_replicas || 1
    number_of_shards = setting&.elasticsearch_shards || 5

    return if ElasticIndexSetting.exists?(alias_name: ALIAS_NAME)

    ElasticIndexSetting.create!(
      alias_name: ALIAS_NAME,
      number_of_replicas: number_of_replicas,
      number_of_shards: number_of_shards
    )
  end

  def down
    ElasticIndexSetting.where(alias_name: ALIAS_NAME).delete_all
  end
end
