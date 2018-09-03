module Ci
  class BuildConfigValue < ActiveRecord::Base
    extend Gitlab::Ci::Model

    # The version of the schema that first introduced this model/table.
    MINIMUM_SCHEMA_VERSION = 20180831115822

    def self.available?
      @available ||=
        ActiveRecord::Migrator.current_version >= MINIMUM_SCHEMA_VERSION
    end

    self.table_name = 'ci_builds_config_values'

    belongs_to :build
    
    enum key: [
      :image,
      :service,
      :artifacts_name,
      :artifacts_untracked,
      :artifacts_path,
      :artifacts_report_junit,
      :artifacts_when,
      :artifacts_expire_in,
      :cache_key,
      :cache_untracked,
      :cache_paths,
      :cache_policy,
      :dependency,
      :before_script,
      :script,
      :after_script,
      :environment_name,
      :environment_url,
      :environment_action,
      :retry,
    ]
  end
end
