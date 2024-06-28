# frozen_string_literal: true

require 'resolv'

class InstanceConfiguration
  SSH_ALGORITHMS = %w[DSA ECDSA ED25519 RSA].freeze
  SSH_ALGORITHMS_PATH = '/etc/ssh/'
  CACHE_KEY = 'instance_configuration'
  EXPIRATION_TIME = 24.hours

  def settings
    @configuration ||= Rails.cache.fetch(CACHE_KEY, expires_in: EXPIRATION_TIME) do
      configuration
    end
  end

  private

  def configuration
    { ssh_algorithms_hashes: ssh_algorithms_hashes,
      host: host,
      gitlab_pages: gitlab_pages,
      ci_cd_limits: ci_cd_limits,
      size_limits: size_limits,
      package_file_size_limits: package_file_size_limits,
      rate_limits: rate_limits }.deep_symbolize_keys
  end

  def ssh_algorithms_hashes
    SSH_ALGORITHMS.select { |algo| ssh_algorithm_enabled?(algo) }.map { |algo| ssh_algorithm_hashes(algo) }.compact
  end

  def ssh_algorithm_enabled?(algorithm)
    algorithm_key_restriction = application_settings["#{algorithm.downcase}_key_restriction"]
    algorithm_key_restriction.nil? || algorithm_key_restriction != ApplicationSetting::FORBIDDEN_KEY_VALUE
  end

  def host
    Settings.gitlab.host
  end

  def gitlab_pages
    Settings.pages.to_h.merge(ip_address: resolv_dns(Settings.pages.host))
  end

  def resolv_dns(dns)
    Resolv.getaddress(dns)
  rescue Resolv::ResolvError
  end

  def size_limits
    {
      max_attachment_size: application_settings[:max_attachment_size].megabytes,
      receive_max_input_size: application_settings[:receive_max_input_size]&.megabytes,
      max_export_size: application_settings[:max_export_size] > 0 ? application_settings[:max_export_size].megabytes : nil,
      max_import_size: application_settings[:max_import_size] > 0 ? application_settings[:max_import_size].megabytes : nil,
      diff_max_patch_bytes: application_settings[:diff_max_patch_bytes].bytes,
      max_artifacts_size: application_settings[:max_artifacts_size].megabytes,
      max_pages_size: application_settings[:max_pages_size] > 0 ? application_settings[:max_pages_size].megabytes : nil,
      snippet_size_limit: application_settings[:snippet_size_limit]&.bytes,
      max_import_remote_file_size: application_settings[:max_import_remote_file_size] > 0 ? application_settings[:max_import_remote_file_size].megabytes : 0,
      bulk_import_max_download_file_size: application_settings[:bulk_import_max_download_file_size] > 0 ? application_settings[:bulk_import_max_download_file_size].megabytes : 0
    }
  end

  def package_file_size_limits
    Plan.all.to_h { |plan| [plan.name.capitalize, plan_file_size_limits(plan)] }
  end

  def plan_file_size_limits(plan)
    {
      conan: plan.actual_limits[:conan_max_file_size],
      helm: plan.actual_limits[:helm_max_file_size],
      maven: plan.actual_limits[:maven_max_file_size],
      npm: plan.actual_limits[:npm_max_file_size],
      nuget: plan.actual_limits[:nuget_max_file_size],
      pypi: plan.actual_limits[:pypi_max_file_size],
      terraform_module: plan.actual_limits[:terraform_module_max_file_size],
      generic: plan.actual_limits[:generic_packages_max_file_size]
    }
  end

  def rate_limits
    {
      unauthenticated: {
        enabled: application_settings[:throttle_unauthenticated_enabled],
        requests_per_period: application_settings[:throttle_unauthenticated_requests_per_period],
        period_in_seconds: application_settings[:throttle_unauthenticated_period_in_seconds]
      },
      authenticated_api: {
        enabled: application_settings[:throttle_authenticated_api_enabled],
        requests_per_period: application_settings[:throttle_authenticated_api_requests_per_period],
        period_in_seconds: application_settings[:throttle_authenticated_api_period_in_seconds]
      },
      authenticated_web: {
        enabled: application_settings[:throttle_authenticated_web_enabled],
        requests_per_period: application_settings[:throttle_authenticated_web_requests_per_period],
        period_in_seconds: application_settings[:throttle_authenticated_web_period_in_seconds]
      },
      protected_paths: {
        enabled: application_settings[:throttle_protected_paths_enabled],
        requests_per_period: application_settings[:throttle_protected_paths_requests_per_period],
        period_in_seconds: application_settings[:throttle_protected_paths_period_in_seconds]
      },
      unauthenticated_packages_api: {
        enabled: application_settings[:throttle_unauthenticated_packages_api_enabled],
        requests_per_period: application_settings[:throttle_unauthenticated_packages_api_requests_per_period],
        period_in_seconds: application_settings[:throttle_unauthenticated_packages_api_period_in_seconds]
      },
      authenticated_packages_api: {
        enabled: application_settings[:throttle_authenticated_packages_api_enabled],
        requests_per_period: application_settings[:throttle_authenticated_packages_api_requests_per_period],
        period_in_seconds: application_settings[:throttle_authenticated_packages_api_period_in_seconds]
      },
      authenticated_git_lfs_api: {
        enabled: application_settings[:throttle_authenticated_git_lfs_enabled],
        requests_per_period: application_settings[:throttle_authenticated_git_lfs_requests_per_period],
        period_in_seconds: application_settings[:throttle_authenticated_git_lfs_period_in_seconds]
      },
      issue_creation: application_setting_limit_per_minute(:issues_create_limit),
      note_creation: application_setting_limit_per_minute(:notes_create_limit),
      project_export: application_setting_limit_per_minute(:project_export_limit),
      project_export_download: application_setting_limit_per_minute(:project_download_export_limit),
      project_import: application_setting_limit_per_minute(:project_import_limit),
      group_export: application_setting_limit_per_minute(:group_export_limit),
      group_export_download: application_setting_limit_per_minute(:group_download_export_limit),
      group_import: application_setting_limit_per_minute(:group_import_limit),
      raw_blob: application_setting_limit_per_minute(:raw_blob_request_limit),
      search_rate_limit: application_setting_limit_per_minute(:search_rate_limit),
      search_rate_limit_unauthenticated: application_setting_limit_per_minute(:search_rate_limit_unauthenticated),
      users_get_by_id: {
        enabled: application_settings[:users_get_by_id_limit] > 0,
        requests_per_period: application_settings[:users_get_by_id_limit],
        period_in_seconds: 10.minutes
      }
    }
  end

  def ci_cd_limits
    Plan.all.to_h { |plan| [plan.name.capitalize, plan_ci_cd_limits(plan)] }
  end

  def plan_ci_cd_limits(plan)
    plan.actual_limits.slice(
      :ci_pipeline_size,
      :ci_active_jobs,
      :ci_project_subscriptions,
      :ci_pipeline_schedules,
      :ci_needs_size_limit,
      :ci_registered_group_runners,
      :ci_registered_project_runners
    )
  end

  def ssh_algorithm_file(algorithm)
    File.join(SSH_ALGORITHMS_PATH, "ssh_host_#{algorithm.downcase}_key.pub")
  end

  def ssh_algorithm_hashes(algorithm)
    content = ssh_algorithm_file_content(algorithm)
    return unless content.present?

    { name: algorithm,
      md5: ssh_algorithm_md5(content),
      sha256: ssh_algorithm_sha256(content) }
  end

  def ssh_algorithm_file_content(algorithm)
    file = ssh_algorithm_file(algorithm)
    return unless File.exist?(file)

    File.read(file)
  end

  def ssh_algorithm_md5(ssh_file_content)
    Gitlab::SSHPublicKey.new(ssh_file_content).fingerprint
  end

  def ssh_algorithm_sha256(ssh_file_content)
    Gitlab::SSHPublicKey.new(ssh_file_content).fingerprint_sha256
  end

  def application_settings
    Gitlab::CurrentSettings.current_application_settings
  end

  def application_setting_limit_per_minute(setting)
    {
      enabled: application_settings[setting] > 0,
      requests_per_period: application_settings[setting],
      period_in_seconds: 1.minute
    }
  end
end

InstanceConfiguration.prepend_mod_with('InstanceConfiguration')
