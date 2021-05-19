# frozen_string_literal: true

module Gitlab
  class EncryptedConfiguration
    delegate :[], :fetch, to: :config
    delegate_missing_to :options
    attr_reader :content_path, :key, :previous_keys

    CIPHER = "aes-256-gcm"
    SALT = "GitLabEncryptedConfigSalt"

    class MissingKeyError < RuntimeError
      def initialize(msg = "Missing encryption key to encrypt/decrypt file with.")
        super
      end
    end

    class InvalidConfigError < RuntimeError
      def initialize(msg = "Content was not a valid yml config file")
        super
      end
    end

    def self.generate_key(base_key)
      # Because the salt is static, we want uniqueness to be coming from the base_key
      # Error if the base_key is empty or suspiciously short
      raise 'Base key too small' if base_key.blank? || base_key.length < 16

      ActiveSupport::KeyGenerator.new(base_key).generate_key(SALT, ActiveSupport::MessageEncryptor.key_len(CIPHER))
    end

    def initialize(content_path: nil, base_key: nil, previous_keys: [])
      @content_path = Pathname.new(content_path).yield_self { |path| path.symlink? ? path.realpath : path } if content_path
      @key = self.class.generate_key(base_key) if base_key
      @previous_keys = previous_keys
    end

    def active?
      content_path&.exist?
    end

    def read
      if active?
        decrypt(content_path.binread)
      else
        ""
      end
    end

    def write(contents)
      # ensure contents are valid to deserialize before write
      deserialize(contents)

      temp_file = Tempfile.new(File.basename(content_path), File.dirname(content_path))
      File.open(temp_file.path, 'wb') do |file|
        file.write(encrypt(contents))
      end
      FileUtils.mv(temp_file.path, content_path)
    ensure
      temp_file&.unlink
    end

    def config
      return @config if @config

      contents = deserialize(read)

      raise InvalidConfigError unless contents.is_a?(Hash)

      @config = contents.deep_symbolize_keys
    end

    def change(&block)
      writing(read, &block)
    end

    private

    def writing(contents)
      updated_contents = yield contents

      write(updated_contents) if updated_contents != contents
    end

    def encrypt(contents)
      handle_missing_key!
      encryptor.encrypt_and_sign(contents)
    end

    def decrypt(contents)
      handle_missing_key!
      encryptor.decrypt_and_verify(contents)
    end

    def encryptor
      return @encryptor if @encryptor

      @encryptor = ActiveSupport::MessageEncryptor.new(key, cipher: CIPHER)

      # Allow fallback to previous keys
      @previous_keys.each do |key|
        @encryptor.rotate(self.class.generate_key(key))
      end

      @encryptor
    end

    def options
      # Allows top level keys to be referenced using dot syntax
      @options ||= ActiveSupport::InheritableOptions.new(config)
    end

    def deserialize(contents)
      YAML.safe_load(contents, permitted_classes: [Symbol]).presence || {}
    end

    def handle_missing_key!
      raise MissingKeyError if @key.nil?
    end
  end
end
