module Ci
  class BuildConfig < ActiveRecord::Base
    extend Gitlab::Ci::Model

    # The version of the schema that first introduced this model/table.
    MINIMUM_SCHEMA_VERSION = 20180831115821

    def self.available?
      @available ||=
        ActiveRecord::Migrator.current_version >= MINIMUM_SCHEMA_VERSION
    end

    self.table_name = 'ci_builds_config'

    belongs_to :build

    serialize :yaml_options # rubocop:disable Cop/ActiveRecordSerialize
    serialize :yaml_variables, Gitlab::Serializer::Ci::Variables # rubocop:disable Cop/ActiveRecordSerialize
  end
end
