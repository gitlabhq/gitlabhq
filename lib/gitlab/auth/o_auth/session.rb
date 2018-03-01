# :nocov:
module Gitlab
  module Auth
    module OAuth
      module Session
        def self.create(provider, ticket)
          Rails.cache.write("gitlab:#{provider}:#{ticket}", ticket, expires_in: Gitlab.config.omniauth.cas3.session_duration)
        end

        def self.destroy(provider, ticket)
          Rails.cache.delete("gitlab:#{provider}:#{ticket}")
        end

        def self.valid?(provider, ticket)
          Rails.cache.read("gitlab:#{provider}:#{ticket}").present?
        end
      end
    end
  end
end
# :nocov:
