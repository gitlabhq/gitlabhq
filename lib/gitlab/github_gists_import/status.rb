# frozen_string_literal: true

module Gitlab
  module GithubGistsImport
    class Status
      IMPORT_STATUS_KEY = 'gitlab:github-gists-import:%{user_id}'
      EXPIRATION_TIME = 24.hours

      def initialize(user_id)
        @user_id = user_id
      end

      def start!
        change_status('started')
      end

      def fail!
        change_status('failed')
      end

      def finish!
        change_status('finished')
      end

      def started?
        Gitlab::Redis::SharedState.with { |redis| redis.get(import_status_key) == 'started' }
      end

      private

      def change_status(status_name)
        Gitlab::Redis::SharedState.with do |redis|
          redis.set(import_status_key, status_name)
          redis.expire(import_status_key, EXPIRATION_TIME) unless status_name == 'started'
        end
      end

      def import_status_key
        format(IMPORT_STATUS_KEY, user_id: @user_id)
      end
    end
  end
end
