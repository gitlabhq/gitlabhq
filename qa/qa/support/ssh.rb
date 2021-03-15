# frozen_string_literal: true

require 'tempfile'
require 'etc'

module QA
  module Support
    class SSH
      include Scenario::Actable
      include Support::Run

      attr_accessor :known_hosts_file, :private_key_file, :key
      attr_reader :uri

      def initialize
        @private_key_file = Tempfile.new("id_#{SecureRandom.hex(8)}")
        @known_hosts_file = Tempfile.new("known_hosts_#{SecureRandom.hex(8)}")
      end

      def uri=(address)
        @uri = URI(address)
      end

      def setup(env: nil)
        File.binwrite(private_key_file, key.private_key)
        File.chmod(0700, private_key_file)

        keyscan_params = ['-H']
        keyscan_params << "-p #{uri_port}" if uri_port
        keyscan_params << uri.host

        res = run("ssh-keyscan #{keyscan_params.join(' ')} >> #{known_hosts_file.path}", env: env, log_prefix: 'SSH: ')
        return res.response unless res.success?

        true
      end

      def delete
        private_key_file.close(true)
        known_hosts_file.close(true)
      end

      def reset_2fa_codes
        ssh_params = [uri.host]
        ssh_params << "-p #{uri_port}" if uri_port
        ssh_params << "2fa_recovery_codes"

        run("echo yes | ssh -i #{private_key_file.path} -o UserKnownHostsFile=#{known_hosts_file.path} #{git_user}@#{ssh_params.join(' ')}", log_prefix: 'SSH: ').to_s
      end

      private

      def uri_port
        use_typical_params? ? nil : uri.port
      end

      def git_user
        QA::Runtime::Env.running_in_ci? || use_typical_params? ? 'git' : Etc.getlogin
      end

      # Checks if typical parameters should be used. That means the SSH port will not be
      # needed because it's port 22, and the git user is named 'git'. We assume that
      # typical parameters should be used if the host URI includes a typical HTTP(S)
      # port (80 or 443)
      #
      # @return [Boolean] whether typical SSH port and git user parameters should be used
      def use_typical_params?
        [443, 80].include?(uri.port)
      end
    end
  end
end
