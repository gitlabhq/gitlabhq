# frozen_string_literal: true

module Clusters
  module Agents
    module Authorizations
      module CiAccess
        class FilterService
          def initialize(authorizations, filter_params)
            @authorizations = authorizations
            @filter_params = filter_params

            @environments_matcher = {}
          end

          def execute
            filter_by_environment(authorizations)
          end

          private

          attr_reader :authorizations, :filter_params

          def filter_by_environment(auths)
            return auths unless filter_by_environment?

            auths.select do |auth|
              next true if auth.config['environments'].blank?

              auth.config['environments'].any? { |environment_pattern| matches_environment?(environment_pattern) }
            end
          end

          def filter_by_environment?
            filter_params.has_key?(:environment)
          end

          def environment_filter
            @environment_filter ||= filter_params[:environment]
          end

          def matches_environment?(environment_pattern)
            return false if environment_filter.nil?

            environments_matcher(environment_pattern).match?(environment_filter)
          end

          def environments_matcher(environment_pattern)
            @environments_matcher[environment_pattern] ||= ::Gitlab::Ci::EnvironmentMatcher.new(environment_pattern)
          end
        end
      end
    end
  end
end
