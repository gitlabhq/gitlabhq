module Gitlab
  module LDAP
    class Adapter
      attr_reader :ldap

      def initialize
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

        @ldap = Net::LDAP.new(options)
      end

      def users(field, value)
        if field.to_sym == :dn
          options = {
            base: value
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

        entries = ldap.search(options).select do |entry|
          entry.respond_to? config.uid
        end

        entries.map do |entry|
          Gitlab::LDAP::Person.new(entry)
        end
      end

      def user(*args)
        users(*args).first
      end

      private

      def config
        @config ||= Gitlab.config.ldap
      end
    end
  end
end
