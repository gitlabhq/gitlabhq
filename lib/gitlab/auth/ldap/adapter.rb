# frozen_string_literal: true

module Gitlab
  module Auth
    module Ldap
      class Adapter
        SEARCH_RETRY_FACTOR = [1, 1, 2, 3].freeze
        MAX_SEARCH_RETRIES = Rails.env.test? ? 1 : SEARCH_RETRY_FACTOR.size

        attr_reader :provider, :ldap

        def self.open(provider, &block)
          Net::LDAP.open(config(provider).adapter_options) do |ldap|
            yield(self.new(provider, ldap))
          end
        end

        def self.config(provider)
          Gitlab::Auth::Ldap::Config.new(provider)
        end

        def initialize(provider, ldap = nil)
          @provider = provider
          @ldap = ldap || renew_connection_adapter
        end

        def config
          Gitlab::Auth::Ldap::Config.new(provider)
        end

        def users(fields, value, limit = nil)
          options = user_options(Array(fields), value, limit)
          users_search(options)
        end

        def user(...)
          users(...).first
        end

        def dn_matches_filter?(dn, filter)
          ldap_search(base: dn,
            filter: filter,
            scope: Net::LDAP::SearchScope_BaseObject,
            attributes: %w[dn]).any?
        end

        def ldap_search(*args)
          retries ||= 0

          # Net::LDAP's `time` argument doesn't work. Use Ruby `Timeout` instead.
          Timeout.timeout(timeout_time(retries)) do
            results = ldap.search(*args)

            if results.nil?
              response = ldap.get_operation_result
              check_empty_response_code(response)
              []
            else
              results
            end
          end
        rescue Net::LDAP::Error, Timeout::Error => error
          retries += 1
          error_message = connection_error_message(error)

          Gitlab::AppLogger.warn(error_message)

          if retries < MAX_SEARCH_RETRIES
            renew_connection_adapter
            retry
          else
            raise LdapConnectionError, error_message
          end
        end

        private

        def timeout_time(retry_number)
          SEARCH_RETRY_FACTOR[retry_number] * config.timeout
        end

        def users_search(options)
          entries = ldap_search(options).select do |entry|
            entry.respond_to? config.uid
          end

          entries.map do |entry|
            Gitlab::Auth::Ldap::Person.new(entry, provider)
          end
        end

        def user_options(fields, value, limit)
          options = {
            attributes: Gitlab::Auth::Ldap::Person.ldap_attributes(config),
            base: config.base
          }

          options[:size] = limit if limit

          if fields.include?('dn')
            raise ArgumentError, 'It is not currently possible to search the DN and other fields at the same time.' if fields.size > 1

            options[:base] = value
            options[:scope] = Net::LDAP::SearchScope_BaseObject
          else
            filter = fields.map { |field| Net::LDAP::Filter.eq(field, value) }.inject(:|)
          end

          options.merge(filter: user_filter(filter))
        end

        def user_filter(filter = nil)
          user_filter = config.constructed_user_filter if config.user_filter.present?

          if user_filter && filter
            Net::LDAP::Filter.join(filter, user_filter)
          elsif user_filter
            user_filter
          else
            filter
          end
        end

        def connection_error_message(exception)
          if exception.is_a?(Timeout::Error)
            "LDAP search timed out after #{config.timeout} seconds"
          else
            "LDAP search raised exception #{exception.class}: #{exception.message}"
          end
        end

        def renew_connection_adapter
          @ldap = Net::LDAP.new(config.adapter_options)
        end

        def check_empty_response_code(response)
          if config.retry_empty_result_with_codes.include?(response.code)
            raise Net::LDAP::Error, "Got empty results with response code: #{response.code}, message: #{response.message}"
          end

          unless response.code == 0
            Gitlab::AppLogger.warn("LDAP search error: #{response.message}")
          end
        end
      end
    end
  end
end

Gitlab::Auth::Ldap::Adapter.prepend_mod_with('Gitlab::Auth::Ldap::Adapter')
