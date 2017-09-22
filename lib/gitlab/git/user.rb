module Gitlab
  module Git
    class User
      attr_reader :name, :email, :gl_id

      def self.from_gitlab(gitlab_user)
        new(gitlab_user.name, gitlab_user.email, Gitlab::GlId.gl_id(gitlab_user))
      end

      def self.from_gitaly(gitaly_user)
        new(gitaly_user.name, gitaly_user.email, gitaly_user.gl_id)
      end

      def initialize(name, email, gl_id)
        @name = name
        @email = email
        @gl_id = gl_id
      end

      def ==(other)
        [name, email, gl_id] == [other.name, other.email, other.gl_id]
      end
    end
  end
end
