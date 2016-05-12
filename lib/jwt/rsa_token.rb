module JWT
  class RSAToken < Token
    attr_reader :key_file

    def initialize(key_file)
      super()
      @key_file = key_file
    end

    def encoded
      headers = {
        kid: kid
      }
      JWT.encode(payload, key, 'RS256', headers)
    end

    private

    def key_data
      @key_data ||= File.read(key_file)
    end

    def key
      @key ||= OpenSSL::PKey::RSA.new(key_data)
    end

    def kid
      sha256 = Digest::SHA256.new
      sha256.update(key.public_key.to_der)
      payload = StringIO.new(sha256.digest).read(30)
      Base32.encode(payload).split('').each_slice(4).each_with_object([]) do |slice, mem|
        mem << slice.join
      end.join(':')
    end
  end
end
