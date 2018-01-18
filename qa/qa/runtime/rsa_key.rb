require 'net/ssh'
require 'forwardable'

module QA
  module Runtime
    class RSAKey
      extend Forwardable

      def initialize(bits = 4096)
        @key = OpenSSL::PKey::RSA.new(bits)
      end

      attr_reader :key
      def_delegators :@key, :fingerprint

      def public_key
        @public_key ||= "#{key.ssh_type} #{[key.to_blob].pack('m0')}"
      end
    end
  end
end
