require 'net/ssh'
require 'forwardable'

module QA
  module Runtime
    class RSAKey
      extend Forwardable

      attr_reader :key
      def_delegators :@key, :fingerprint, :to_pem

      def initialize(bits = 4096)
        @key = OpenSSL::PKey::RSA.new(bits)
      end

      def public_key
        @public_key ||= "#{key.ssh_type} #{[key.to_blob].pack('m0')}"
      end
    end
  end
end
