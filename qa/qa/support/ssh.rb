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
        uri.port && (uri.port != 80) ? uri.port : nil
      end

      def git_user
        QA::Runtime::Env.running_in_ci? || [443, 80].include?(uri.port) ? 'git' : Etc.getlogin
      end
    end
  end
end
