# frozen_string_literal: true

module EE
  module Gitlab
    module UsageData
      extend ::Gitlab::Utils::Override

      override :features_usage_data
      def features_usage_data
        super.merge(features_usage_data_ee)
      end

      def features_usage_data_ee
        {
          elasticsearch_enabled: ::Gitlab::CurrentSettings.elasticsearch_search?,
          geo_enabled: ::Gitlab::Geo.enabled?
        }
      end

      override :license_usage_data
      def license_usage_data
        usage_data = super
        license = ::License.current
        usage_data[:edition] =
          if license
            license.edition
          else
            'EE Free'
          end

        if license
          usage_data[:license_md5] = license.md5
          usage_data[:license_id] = license.license_id
          usage_data[:historical_max_users] = ::HistoricalData.max_historical_user_count
          usage_data[:licensee] = license.licensee
          usage_data[:license_user_count] = license.restricted_user_count
          usage_data[:license_starts_at] = license.starts_at
          usage_data[:license_expires_at] = license.expires_at
          usage_data[:license_plan] = license.plan
          usage_data[:license_add_ons] = license.add_ons
          usage_data[:license_trial] = license.trial?
        end

        usage_data
      end

      def projects_mirrored_with_pipelines_enabled
        count(::Project.joins(:project_feature).where(
                mirror: true,
                mirror_trigger_builds: true,
                project_features: {
                  builds_access_level: ::ProjectFeature::ENABLED
                }
        ))
      end

      def service_desk_counts
        return {} unless ::License.feature_available?(:service_desk)

        projects_with_service_desk = ::Project.where(service_desk_enabled: true)

        {
          service_desk_enabled_projects: count(projects_with_service_desk),
          service_desk_issues: count(::Issue.where(
                                       project: projects_with_service_desk,
                                       author: ::User.support_bot,
                                       confidential: true
          ))
        }
      end

      def security_products_usage
        types = {
          container_scanning: :container_scanning_jobs,
          dast: :dast_jobs,
          dependency_scanning: :dependency_scanning_jobs,
          license_management: :license_management_jobs,
          sast: :sast_jobs
        }

        results = count(::Ci::Build.where(name: types.keys).group(:name))
        results.each_with_object({}) { |(key, value), response| response[types[key.to_sym]] = value  }
      end

      override :system_usage_data
      def system_usage_data
        usage_data = super

        usage_data[:counts] = usage_data[:counts].merge({
          epics: count(::Epic),
          geo_nodes: count(::GeoNode),
          ldap_group_links: count(::LdapGroupLink),
          ldap_keys: count(::LDAPKey),
          ldap_users: count(::User.ldap),
          projects_reporting_ci_cd_back_to_github: count(::GithubService.without_defaults.active),
          projects_mirrored_with_pipelines_enabled: projects_mirrored_with_pipelines_enabled
        }).merge(service_desk_counts).merge(security_products_usage)

        usage_data
      end
    end
  end
end
