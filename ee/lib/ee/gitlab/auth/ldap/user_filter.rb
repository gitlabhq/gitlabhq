module EE
  module Gitlab
    module Auth
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
            logger.debug "Running filter #{@filter} against #{@proxy.provider}"

            @proxy.adapter.ldap_search(options).map(&:dn).tap do |dns|
              logger.debug "Found #{dns.count} mathing users for filter #{@filter}"
            end
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

          def logger
            Rails.logger
          end
        end
      end
    end
  end
end
