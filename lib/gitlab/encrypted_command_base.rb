# frozen_string_literal: true

# rubocop:disable Rails/Output
module Gitlab
  class EncryptedCommandBase
    DISPLAY_NAME = "Base"
    EDIT_COMMAND_NAME = "base"

    class << self
      def encrypted_secrets(**args)
        raise NotImplementedError
      end

      def write(contents, args: {})
        encrypted = encrypted_secrets(**args)
        return unless validate_config(encrypted)

        validate_contents(contents)
        encrypted.write(contents)

        puts "File encrypted and saved."
      rescue Interrupt
        warn "Aborted changing file: nothing saved."
      rescue ActiveSupport::MessageEncryptor::InvalidMessage
        warn "Couldn't decrypt #{encrypted.content_path}. Perhaps you passed the wrong key?"
      end

      def edit(args: {})
        encrypted = encrypted_secrets(**args)
        return unless validate_config(encrypted)

        if ENV["EDITOR"].blank?
          warn 'No $EDITOR specified to open file. Please provide one when running the command:'
          warn "gitlab-rake #{self::EDIT_COMMAND_NAME} EDITOR=vim"
          return
        end

        temp_file = Tempfile.new(File.basename(encrypted.content_path), File.dirname(encrypted.content_path))
        contents_changed = false

        encrypted.change do |contents|
          contents = encrypted_file_template unless File.exist?(encrypted.content_path)
          File.write(temp_file.path, contents)

          edit_success = system(*editor_args, temp_file.path)

          raise "Unable to run $EDITOR: #{editor_args}" unless edit_success

          changes = File.read(temp_file.path)
          contents_changed = contents != changes
          validate_contents(changes)
          changes
        end

        puts "Contents were unchanged." unless contents_changed
        puts "File encrypted and saved."
      rescue Interrupt
        warn "Aborted changing file: nothing saved."
      rescue ActiveSupport::MessageEncryptor::InvalidMessage
        warn "Couldn't decrypt #{encrypted.content_path}. Perhaps you passed the wrong key?"
      ensure
        temp_file&.unlink
      end

      def show(args: {})
        encrypted = encrypted_secrets(**args)
        return unless validate_config(encrypted)

        puts encrypted.read.presence || "File '#{encrypted.content_path}' does not exist. Use `gitlab-rake #{self::EDIT_COMMAND_NAME}` to change that."
      rescue ActiveSupport::MessageEncryptor::InvalidMessage
        warn "Couldn't decrypt #{encrypted.content_path}. Perhaps you passed the wrong key?"
      end

      def validate_config(encrypted)
        dir_path = File.dirname(encrypted.content_path)

        unless File.exist?(dir_path)
          warn "Directory #{dir_path} does not exist. Create the directory and try again."
          return false
        end

        if encrypted.key.nil?
          warn "Missing encryption key encrypted_settings_key_base."
          return false
        end

        true
      end

      def validate_contents(contents)
        begin
          config = YAML.safe_load(contents, permitted_classes: [Symbol])
          error_contents = "Did not include any key-value pairs" unless config.is_a?(Hash)
        rescue Psych::Exception => e
          error_contents = e.message
        end

        puts "WARNING: Content was not a valid #{self::DISPLAY_NAME} secret yml file. #{error_contents}" if error_contents

        contents
      end

      def encrypted_file_template
        raise NotImplementedError
      end

      def editor_args
        ENV['EDITOR']&.split
      end
    end
  end
end
# rubocop:enable Rails/Output
