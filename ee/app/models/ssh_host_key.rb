# Detected SSH host keys are transiently stored in Redis
class SshHostKey
  class Fingerprint < Gitlab::KeyFingerprint
    attr_reader :index

    def initialize(key, index: nil)
      super(key)

      @index = index
    end

    def as_json(*)
      { bits: bits, fingerprint: fingerprint, type: type, index: index }
    end
  end

  include ReactiveCaching

  self.reactive_cache_key = ->(key) { [key.class.to_s, key.id] }

  # Do not refresh the data in the background - it is not expected to change
  self.reactive_cache_refresh_interval = 15.minutes
  self.reactive_cache_lifetime = 10.minutes

  def self.find_by(opts = {})
    id = opts.fetch(:id, "")
    project_id, url = id.split(':', 2)

    project = Project.where(id: project_id).includes(:import_data).first

    project.presence && new(project: project, url: url)
  end

  def self.fingerprint_host_keys(data)
    return [] unless data.is_a?(String)

    data
      .each_line
      .each_with_index
      .map { |line, index| Fingerprint.new(line, index: index) }
      .select(&:valid?)
  end

  attr_reader :project, :url

  def initialize(project:, url:)
    @project = project
    @url = normalize_url(url)
  end

  def id
    [project.id, url].join(':')
  end

  def as_json(*)
    {
      changes_project_import_data: changes_project_import_data?,
      fingerprints: fingerprints,
      known_hosts: known_hosts
    }
  end

  def known_hosts
    with_reactive_cache { |data| data[:known_hosts] }
  end

  def fingerprints
    @fingerprints ||= self.class.fingerprint_host_keys(known_hosts)
  end

  # Returns true if the known_hosts data differs from that currently set for
  # `project.import_data.ssh_known_hosts`. Ordering is ignored.
  #
  # Ordering is ignored
  def changes_project_import_data?
    our_known_hosts = known_hosts
    project_known_hosts = project.import_data&.ssh_known_hosts

    cleanup(our_known_hosts.to_s) != cleanup(project_known_hosts.to_s)
  end

  def error
    with_reactive_cache { |data| data[:error] }
  end

  def calculate_reactive_cache
    known_hosts, errors, status =
      Open3.popen3({}, *%W[ssh-keyscan -T 5 -p #{url.port} -f-]) do |stdin, stdout, stderr, wait_thr|
        stdin.puts(url.host)
        stdin.close

        [
          cleanup(stdout.read),
          cleanup(stderr.read),
          wait_thr.value
        ]
      end

    # ssh-keyscan returns an exit code 0 in several error conditions, such as an
    # unknown hostname, so check both STDERR and the exit code
    if !status.success? || errors.present?
      Rails.logger.debug("Failed to detect SSH host keys for #{id}: #{errors}")

      return { error: 'Failed to detect SSH host keys' }
    end

    { known_hosts: known_hosts }
  end

  private

  # Remove comments and duplicate entries
  def cleanup(data)
    data
      .each_line
      .map { |line| line unless line.start_with?('#') || line.chomp.empty? }
      .compact
      .uniq
      .sort
      .join
  end

  def normalize_url(url)
    full_url = ::Addressable::URI.parse(url)
    raise ArgumentError.new("Invalid URL") unless full_url&.scheme == 'ssh'

    Addressable::URI.parse("ssh://#{full_url.host}:#{full_url.inferred_port}")
  end
end
