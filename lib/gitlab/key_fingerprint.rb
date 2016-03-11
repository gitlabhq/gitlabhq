module Gitlab
  class KeyFingerprint
    include Gitlab::Popen

    attr_accessor :key

    def initialize(key)
      @key = key
    end

    def fingerprint
      cmd_status = 0
      cmd_output = ''

      Tempfile.open('gitlab_key_file') do |file|
        file.puts key
        file.rewind

        cmd = []
        cmd.push *%W(ssh-keygen)
        cmd.push *%W(-E md5) if explicit_fingerprint_algorithm?
        cmd.push *%W(-lf #{file.path})

        cmd_output, cmd_status = popen(cmd, '/tmp')
      end

      return nil unless cmd_status.zero?

      # 16 hex bytes separated by ':', optionally starting with "MD5:"
      fingerprint_matches = cmd_output.match(/(MD5:)?(?<fingerprint>(\h{2}:){15}\h{2})/)
      return nil unless fingerprint_matches

      fingerprint_matches[:fingerprint]
    end

    private

    def explicit_fingerprint_algorithm?
      # OpenSSH 6.8 introduces a new default output format for fingerprints.
      # Check the version and decide which command to use.

      version_output, version_status = popen(%W(ssh -V))
      return false unless version_status.zero?

      version_matches = version_output.match(/OpenSSH_(?<major>\d+)\.(?<minor>\d+)/)
      return false unless version_matches

      version_info = Gitlab::VersionInfo.new(version_matches[:major].to_i, version_matches[:minor].to_i)

      required_version_info = Gitlab::VersionInfo.new(6, 8)

      version_info >= required_version_info
    end
  end

  #
  # Calculates the fingerprint of a given key without using
  # openssh key validations. For this reason, only use
  # for calculating the fingerprint to find the key with it.
  #
  # DO NOT use it for checking the validity of a ssh key.
  #
  class InsecureKeyFingerprint
    attr_accessor :key

    #
    # Gets the base64 encoded string representing a rsa or dsa key
    #
    def initialize(key_base64)
      @key = key_base64
    end

    def fingerprint
      OpenSSL::Digest::MD5.hexdigest(Base64.decode64(@key)).scan(/../).join(':')
    end
  end
end
