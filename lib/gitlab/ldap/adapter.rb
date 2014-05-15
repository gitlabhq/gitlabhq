module Gitlab
  module LDAP
    class Adapter
      attr_reader :ldap

      def self.open(&block)
        Net::LDAP.open(adapter_options) do |ldap|
          block.call(self.new(ldap))
        end
      end

      def self.config
        Gitlab.config.ldap
      end

      def self.adapter_options
        encryption = config['method'].to_s == 'ssl' ? :simple_tls : nil

        options = {
          host: config['host'],
          port: config['port'],
          encryption: encryption
        }

        auth_options = {
          auth: {
            method: :simple,
            username: config['bind_dn'],
            password: config['password']
          }
        }

        if config['password'] || config['bind_dn']
          options.merge!(auth_options)
        end
        options
      end


      def initialize(ldap=nil)
        @ldap = ldap || Net::LDAP.new(self.class.adapter_options)
      end

      def users(field, value)
        if field.to_sym == :dn
          options = {
            base: value,
            scope: Net::LDAP::SearchScope_BaseObject
          }
        else
          options = {
            base: config['base'],
            filter: Net::LDAP::Filter.eq(field, value)
          }
        end

        if config['user_filter'].present?
          user_filter = Net::LDAP::Filter.construct(config['user_filter'])

          options[:filter] = if options[:filter]
                               Net::LDAP::Filter.join(options[:filter], user_filter)
                             else
                               user_filter
                             end
        end

        entries = ldap_search(options).select do |entry|
          entry.respond_to? config.uid
        end

        entries.map do |entry|
          Gitlab::LDAP::Person.new(entry)
        end
      end

      def user(*args)
        users(*args).first
      end

      def dn_matches_filter?(dn, filter)
        ldap_search(base: dn, filter: filter, scope: Net::LDAP::SearchScope_BaseObject, attributes: %w{dn}).any?
      end

      def ldap_search(*args)
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

      private

      def config
        @config ||= self.class.config
      end
    end
  end
end
