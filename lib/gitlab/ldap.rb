module Gitlab
  class LDAP
    attr_reader :ldap

    def initialize
      @ldap = Net::LDAP.new(
        host: config['host'],
        port: config['port'],
        auth: {
          method: config['method'],
          username: config['bind_dn'],
          password: config['password']
        }
      )
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
        base: "ou=Groups,#{config['base']}",
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
