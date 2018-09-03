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

    STRUCTURE = {
      image: :image,
      services: [:service],
      artifacts: {
        name: :artifacts_name,
        untracked: :artifacts_untracked,
        path: [:artifacts_path],
        reports: {
          junit: [:artifacts_report_junit]
        },
        when: :artifacts_when,
        expire_in: :artifacts_expire_in,
      },
      cache: {
        key: :cache_key,
        untracked: :cache_untracked,
        path: [:cache_paths],
        policy: :cache_policy
      },
      dependencies: [:dependency],
      before_script: [:before_script],
      script: [:script],
      after_script: [:after_script],
      environment: {
        name: :environment_name,
        url: :environment_url,
        action: :environment_action
      },
      retry: :retry
    }

    def options
      demap_data(STRUCTURE, nil)
    end

    def options=(value)
      build.config_values_attributes = map_data(STRUCTURE, value, nil).flatten
    end

    public

    def map_data(data_def, value, index)
      if data_def.is_a?(Symbol)
        map_value(data_def, value, index)
      elsif data_def.is_a?(Hash)
        map_structure(data_def, value, index)
      elsif data_def.is_a?(Array)
        map_array(data_def, value, index)
      else
        raise "Unsupported type for: #{data_def}"
      end
    end

    def map_structure(data_def, hash, index)
      raise 'Invalid data' unless data_def.is_a?(Hash)
      raise 'Value needs to be hash' unless hash.is_a?(Hash)

      data_def.map do |key, data|
        map_data(data, hash[key], index) if hash[key]
      end.compact
    end

    def map_value(key, value, index)
      { key: key, value_string: value, index: index }
    end

    def map_array(data_def, values, index)
      raise 'Invalid data' unless data_def.is_a?(Array)
      raise 'Array needs exactly one' unless data_def.one?
      raise 'Nested arrays are not supported' if index
      raise "Value needs to be array: #{values}" unless values.is_a?(Array)

      type = data_def.first

      values.map.with_index do |value, index|
        map_data(type, value, index)
      end
    end

    public

    def demap_data(data_def, index)
      if data_def.is_a?(Symbol)
        demap_value(data_def, index)
      elsif data_def.is_a?(Hash)
        demap_structure(data_def, index)
      elsif data_def.is_a?(Array)
        demap_array(data_def, index)
      else
        raise "Unsupported type for: #{data_def}"
      end
    end

    def demap_structure(data_def, index)
      raise 'Invalid data' unless data_def.is_a?(Hash)

      data_def = data_def.map do |key, data|
        result = demap_data(data, index)
        [key, result]
      end

      puts "#{data_def}"

      result = data_def.to_h.compact
      result if result.present?
    end

    def demap_array(data_def, index)
      raise 'Invalid data' unless data_def.is_a?(Array)
      raise 'Array needs exactly one' unless data_def.one?
      raise 'Nested arrays are not supported' if index

      type = data_def.first

      results = []

      10000.times do |index|
        result = demap_data(type, index)
        break unless result.present?
        results << result
      end

      results if results.present?
    end

    def demap_value(key, index)
      value = build.config_values.find do |config|
        config.key.to_sym == key && config.index == index
      end
      return unless value

      value.value_string
    end
  end
end
