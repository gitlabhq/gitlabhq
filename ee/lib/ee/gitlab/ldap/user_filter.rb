module EE
  module Gitlab
    module LDAP
      class UserFilter
        def self.filter(*args)
          new(*args).filter
        end

        def initialize(proxy, filter)
          @proxy = proxy
          @filter = filter
        end

        def filter
          @proxy.adapter.ldap_search(options).map(&:dn)
        end

        private

        def options
          { base: config.base, filter: construct_filter }
        end

        def construct_filter
          Net::LDAP::Filter.construct(@filter)
        end

        def config
          @proxy.adapter.config
        end
      end
    end
  end
end
