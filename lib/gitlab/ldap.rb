module Gitlab
  class LDAP
    attr_reader :ldap

    def initialize
      options = {
        host: config['host'],
        port: config['port'],
      }

      auth_options = {
        auth: {
          method: config['method'],
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

      ldap.search(options)
    end

    private

    def config
      @config ||= Gitlab.config.ldap
    end
  end
end
