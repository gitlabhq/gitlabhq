# frozen_string_literal: true

require 'resolv'

class InstanceConfiguration
  SSH_ALGORITHMS = %w(DSA ECDSA ED25519 RSA).freeze
  SSH_ALGORITHMS_PATH = '/etc/ssh/'
  CACHE_KEY = 'instance_configuration'
  EXPIRATION_TIME = 24.hours

  def settings
    @configuration ||= Rails.cache.fetch(CACHE_KEY, expires_in: EXPIRATION_TIME) do
      { ssh_algorithms_hashes: ssh_algorithms_hashes,
        host: host,
        gitlab_pages: gitlab_pages,
        gitlab_ci: gitlab_ci,
        package_file_size_limits: package_file_size_limits,
        rate_limits: rate_limits }.deep_symbolize_keys
    end
  end

  private

  def ssh_algorithms_hashes
    SSH_ALGORITHMS.map { |algo| ssh_algorithm_hashes(algo) }.compact
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

  def gitlab_ci
    Settings.gitlab_ci
            .to_h
            .merge(artifacts_max_size: { value: Gitlab::CurrentSettings.max_artifacts_size.megabytes,
                                         default: 100.megabytes })
  end

  def package_file_size_limits
    Plan.all.to_h { |plan| [plan.name.capitalize, plan_file_size_limits(plan)] }
  end

  def plan_file_size_limits(plan)
    {
      conan: plan.actual_limits[:conan_max_file_size],
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
      issue_creation: application_setting_limit_per_minute(:issues_create_limit),
      note_creation: application_setting_limit_per_minute(:notes_create_limit),
      project_export: application_setting_limit_per_minute(:project_export_limit),
      project_export_download: application_setting_limit_per_minute(:project_download_export_limit),
      project_import: application_setting_limit_per_minute(:project_import_limit),
      group_export: application_setting_limit_per_minute(:group_export_limit),
      group_export_download: application_setting_limit_per_minute(:group_download_export_limit),
      group_import: application_setting_limit_per_minute(:group_import_limit),
      raw_blob: application_setting_limit_per_minute(:raw_blob_request_limit)
    }
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
    Gitlab::SSHPublicKey.new(ssh_file_content).fingerprint('SHA256')
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
