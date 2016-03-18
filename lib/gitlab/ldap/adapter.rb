module Gitlab
  module LDAP
    class Adapter
      attr_reader :provider, :ldap

      def self.open(provider, &block)
        Net::LDAP.open(config(provider).adapter_options) do |ldap|
          block.call(self.new(provider, ldap))
        end
      end

      def self.config(provider)
        Gitlab::LDAP::Config.new(provider)
      end

      def initialize(provider, ldap=nil)
        @provider = provider
        @ldap = ldap || Net::LDAP.new(config.adapter_options)
      end

      def config
        Gitlab::LDAP::Config.new(provider)
      end

      def users(field, value, limit = nil)
        if field.to_sym == :dn
          options = {
            base: value,
            scope: Net::LDAP::SearchScope_BaseObject
          }
        else
          options = {
            base: config.base,
            filter: Net::LDAP::Filter.eq(field, value)
          }
        end

        if config.user_filter.present?
          user_filter = Net::LDAP::Filter.construct(config.user_filter)

          options[:filter] = if options[:filter]
                               Net::LDAP::Filter.join(options[:filter], user_filter)
                             else
                               user_filter
                             end
        end

        if limit.present?
          options.merge!(size: limit)
        end

        entries = ldap_search(options).select do |entry|
          entry.respond_to? config.uid
        end

        entries.map do |entry|
          Gitlab::LDAP::Person.new(entry, provider)
        end
      end

      def user(*args)
        users(*args).first
      end

      def dn_matches_filter?(dn, filter)
        ldap_search(base: dn,
                    filter: filter,
                    scope: Net::LDAP::SearchScope_BaseObject,
                    attributes: %w{dn}).any?
      end

      def ldap_search(*args)
        # Net::LDAP's `time` argument doesn't work. Use Ruby `Timeout` instead.
        Timeout.timeout(config.timeout) do
          results = ldap.search(*args)

          if results.nil?
            response = ldap.get_operation_result

            unless response.code.zero?
              Rails.logger.warn("LDAP search error: #{response.message}")
            end

            []
          else
            results
          end
        end
      rescue Timeout::Error
        Rails.logger.warn("LDAP search timed out after #{config.timeout} seconds")
        []
      end
    end
  end
end
