require 'resolv'

class InstanceConfiguration
  SSH_ALGORITHMS = %w(DSA ECDSA ED25519 RSA).freeze
  SSH_ALGORITHMS_PATH = '/etc/ssh/'.freeze
  CACHE_KEY = 'instance_configuration'.freeze
  EXPIRATION_TIME = 24.hours

  def settings
    @configuration ||= Rails.cache.fetch(CACHE_KEY, expires_in: EXPIRATION_TIME) do
      { ssh_algorithms_hashes: ssh_algorithms_hashes,
        host: host,
        gitlab_pages: gitlab_pages,
        gitlab_ci: gitlab_ci }.deep_symbolize_keys
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
            .merge(artifacts_max_size: { value: Settings.artifacts.max_size&.megabytes,
                                         default: 100.megabytes })
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
    OpenSSL::Digest::MD5.hexdigest(ssh_file_content).scan(/../).join(':')
  end

  def ssh_algorithm_sha256(ssh_file_content)
    OpenSSL::Digest::SHA256.hexdigest(ssh_file_content)
  end
end
