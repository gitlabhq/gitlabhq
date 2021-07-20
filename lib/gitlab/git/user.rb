# frozen_string_literal: true

module Gitlab
  module Git
    class User
      attr_reader :username, :name, :email, :gl_id, :timezone

      def self.from_gitlab(gitlab_user)
        new(gitlab_user.username, gitlab_user.name, gitlab_user.commit_email, Gitlab::GlId.gl_id(gitlab_user), gitlab_user.timezone)
      end

      def self.from_gitaly(gitaly_user)
        new(
          gitaly_user.gl_username,
          Gitlab::EncodingHelper.encode!(gitaly_user.name),
          Gitlab::EncodingHelper.encode!(gitaly_user.email),
          gitaly_user.gl_id,
          gitaly_user.timezone
        )
      end

      def initialize(username, name, email, gl_id, timezone)
        @username = username
        @name = name
        @email = email
        @gl_id = gl_id

        @timezone = if Feature.enabled?(:add_timezone_to_web_operations)
                      timezone
                    else
                      Time.zone.tzinfo.name
                    end
      end

      def ==(other)
        [username, name, email, gl_id, timezone] == [other.username, other.name, other.email, other.gl_id, other.timezone]
      end

      def to_gitaly
        Gitaly::User.new(gl_username: username, gl_id: gl_id, name: name.b, email: email.b, timezone: timezone)
      end
    end
  end
end
