# frozen_string_literal: true

module Clusters
  module Agents
    module Authorizations
      module CiAccess
        class FilterService
          def initialize(authorizations, filter_params, project)
            @authorizations = authorizations
            @filter_params = filter_params
            @project = project

            @environments_matcher = {}
          end

          def execute
            filtered_authorizations = filter_by_environment(authorizations)
            if Feature.enabled?(:kubernetes_agent_protected_branches, project)
              filtered_authorizations = filter_protected_ref(filtered_authorizations)
            end

            filtered_authorizations
          end

          private

          attr_reader :authorizations, :filter_params, :project

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

          def filter_protected_ref(authorizations)
            # we deny all if the protected_ref is not set, since we can't check if the branch is protected:
            return [] unless protected_ref_filter_present?

            # when the branch is protected we don't need to check the authorization settings
            return authorizations if filter_params[:protected_ref]

            authorizations.reject do |authorization|
              only_run_on_protected_ref?(authorization)
            end
          end

          def protected_ref_filter_present?
            filter_params.has_key?(:protected_ref)
          end

          def only_run_on_protected_ref?(authorization)
            authorization.config['protected_branches_only']
          end
        end
      end
    end
  end
end
