# frozen_string_literal: true

module Gitlab
  # noinspection RubyClassModuleNamingConvention -- This is already fixed in an upcoming RubyMine release
  module Fp
    module Settings
      # The PublicApi module is the public interface that a domain-specific Settings module can
      # extend to retrieve settings values.
      #
      # It DRYs up and encapsulates error handling and the transformation of the "ServiceResponse"
      # type structure returned by the `#get_settings` method of the "settings_main_class" class.
      #
      # It should be extended in a `YourDomain::Settings` module, so it
      # can be conveniently and concisely called from code within `YourDomain`.
      #
      # Note that the API intentionally does not use named arguments, to allow it to be called
      # more concisely.
      #
      # The extending class must implement the following method:
      #
      # - `YourDomain::Settings.settings_main_class`: Returns the class that implements the
      #   `#get_settings` method.
      module PublicApi
        # @param [Array<Symbol>] setting_names
        # @param [Hash] options
        # @return [Object]
        # @raise [RuntimeError]
        def get(setting_names, options = {})
          unless setting_names.is_a?(Array) && setting_names.all?(Symbol)
            raise "setting_names arg must be an Array of Symbols"
          end

          response_hash = settings_main_class.get_settings(requested_setting_names: setting_names, options: options)

          raise response_hash.fetch(:message).to_s if response_hash.fetch(:status) == :error

          settings = response_hash.fetch(:settings)

          invalid_settings = setting_names.each_with_object([]) do |setting_name, invalid_settings|
            invalid_settings << setting_name unless settings.key?(setting_name)
          end

          raise "Unsupported setting name(s): #{invalid_settings.join(', ')}" unless invalid_settings.empty?

          settings.slice(*setting_names).to_h
        end

        # @param [Symbol] setting_name
        # @param [Hash] options
        # @return [Object]
        # @raise [RuntimeError]
        def get_single_setting(setting_name, options = {})
          get([setting_name], options).fetch(setting_name)
        end
      end
    end
  end
end
