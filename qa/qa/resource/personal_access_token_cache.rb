# frozen_string_literal: true

module QA
  module Resource
    class PersonalAccessTokenCache
      @personal_access_tokens = {}

      def self.get_token_for_username(username)
        token = @personal_access_tokens[username]

        log_message = if token
                        %Q[Retrieved cached token for username: #{username}, last six chars of token:#{token[-6..]}]
                      else
                        %Q[No cached token found for username: #{username}]
                      end

        QA::Runtime::Logger.info(log_message)

        token
      end

      def self.set_token_for_username(username, token)
        QA::Runtime::Logger.info(%Q[Caching token for username: #{username}, last six chars of token:#{token[-6..]}])
        @personal_access_tokens[username] = token
      end
    end
  end
end
