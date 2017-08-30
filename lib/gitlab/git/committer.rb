module Gitlab
  module Git
    class Committer
      attr_reader :name, :email, :gl_id

      def self.from_user(user)
        new(user.name, user.email, Gitlab::GlId.gl_id(user))
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
