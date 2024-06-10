# frozen_string_literal: true

module RemoteDevelopment
  module Settings
    # The PublicApi module is the public interface that callers can use to retrieve settings values.
    #
    # It is extended in the RemoteDevelopment::Settings module, which makes all of its methods available to
    # be called directly on the RemoteDevelopment::Settings module.
    #
    # It encapsulates the error handling and transformation of the "ServiceResponse" type structure returned by
    # RemoteDevelopment::Settings::Main.get_settings
    module PublicApi
      # @param [Symbol] setting_name
      # @param [Hash] options
      # @return [Object]
      # @raise [RuntimeError]
      def get_single_setting(setting_name, options = {})
        raise "Setting name must be a Symbol" unless setting_name.is_a?(Symbol)

        is_valid_setting_name = get_all_settings.key?(setting_name)
        raise "Unsupported Remote Development setting name: '#{setting_name}'" unless is_valid_setting_name

        get_all_settings(options).fetch(setting_name)
      end

      # @param [Hash] options
      # @return [Hash]
      # @raise [RuntimeError]
      def get_all_settings(options = {})
        response_hash = RemoteDevelopment::Settings::Main.get_settings({ options: options })

        raise response_hash.fetch(:message).to_s if response_hash.fetch(:status) == :error

        response_hash.fetch(:settings).to_h
      end
    end
  end
end
