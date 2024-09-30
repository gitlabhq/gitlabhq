# frozen_string_literal: true

require "yaml"

module QA
  module Tools
    module Ci
      class FfChanges
        include Helpers

        def initialize(mr_diff)
          @mr_diff = mr_diff
        end

        # Return list of feature flags changed in mr with inverse or deleted state
        #
        # @return [String]
        def fetch
          logger.info("Detecting feature flag changes")
          ff_toggles = mr_diff.map do |change|
            ff_yaml = ff_yaml_for_file(change)
            next unless ff_yaml

            state = if ff_yaml[:deleted]
                      "deleted"
                    else
                      ff_yaml[:default_enabled] ? 'disabled' : 'enabled'
                    end

            logger.info(" found changes in feature flag '#{ff_yaml[:name]}'")
            "#{ff_yaml[:name]}=#{state}"
          end.compact

          if ff_toggles.empty?
            logger.info(" no changes to feature flags detected, skipping!")
            return
          end

          logger.info(" constructed feature flag states: '#{ff_toggles}'")
          ff_toggles.join(",")
        end

        private

        attr_reader :mr_diff

        # Loads the YAML feature flag definition based on changed files in merge requests.
        # The definition is loaded from the definition file itself.
        #
        # @param [Hash] change mr file change
        # @return [Hash] a hash containing the YAML data for the feature flag definition
        def ff_yaml_for_file(change)
          return unless %r{/feature_flags/.*\.yml}.match?(change[:path])

          if change[:deleted_file]
            return { name: change[:path].split("/").last.gsub(/\.(yml|yaml)/, ""), deleted: true }
          end

          YAML.safe_load(
            File.read(File.expand_path("../#{change[:path]}", QA::Runtime::Path.qa_root)),
            symbolize_names: true
          )
        end
      end
    end
  end
end
