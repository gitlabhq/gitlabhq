#-------------------------------------------------------------------
#
# Copyright (C) 2013 GitLab.com - Distributed under the MIT Expat License
#
#-------------------------------------------------------------------

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

      # Get LDAP groups from ou=Groups
      #
      # cn - filter groups by name
      #
      # Ex.
      #   groups("dev*") # return all groups start with 'dev'
      #
      def groups(cn = "*")
        options = {
          base: config['group_base'],
          filter: Net::LDAP::Filter.eq("cn", cn)
        }

        ldap.search(options).map do |entry|
          Gitlab::LDAP::Group.new(entry)
        end
      end

      def users(opts)
        if opts.respond_to? :key?
          key, uid = opts.keys.first, opts.values.first
        else
          key, uid = config.uid, opts || "*"
        end

        options = {
          base: config['base'],
          filter: Net::LDAP::Filter.eq(key, uid)
        }

        entries = ldap.search(options).select do |entry|
          entry.respond_to? config.uid
        end

        entries.map do |entry|
          Gitlab::LDAP::Person.new(entry)
        end
      end

      def user(opts)
        users(opts).first
      end

      private

      def config
        @config ||= Gitlab.config.ldap
      end
    end
  end
end
