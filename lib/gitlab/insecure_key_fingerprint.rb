module Gitlab
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
