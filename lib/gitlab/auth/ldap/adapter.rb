module Gitlab
  module Auth
    module LDAP
      class Adapter
        attr_reader :provider, :ldap

        def self.open(provider, &block)
          Net::LDAP.open(config(provider).adapter_options) do |ldap|
            block.call(self.new(provider, ldap))
          end
        end

        def self.config(provider)
          Gitlab::Auth::LDAP::Config.new(provider)
        end

        def initialize(provider, ldap = nil)
          @provider = provider
          @ldap = ldap || Net::LDAP.new(config.adapter_options)
        end

        def config
          Gitlab::Auth::LDAP::Config.new(provider)
        end

        def users(fields, value, limit = nil)
          options = user_options(Array(fields), value, limit)

          entries = ldap_search(options).select do |entry|
            entry.respond_to? config.uid
          end

          entries.map do |entry|
            Gitlab::Auth::LDAP::Person.new(entry, provider)
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
        rescue Net::LDAP::Error => error
          Rails.logger.warn("LDAP search raised exception #{error.class}: #{error.message}")
          []
        rescue Timeout::Error
          Rails.logger.warn("LDAP search timed out after #{config.timeout} seconds")
          []
        end

        private

        def user_options(fields, value, limit)
          options = {
            attributes: Gitlab::Auth::LDAP::Person.ldap_attributes(config),
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
      end
    end
  end
end
