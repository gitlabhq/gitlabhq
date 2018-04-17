module Gitlab
  module GlId
    def self.gl_id(user)
      if user.present?
        "user-#{user.id}"
      else
        ""
      end
    end
  end
end
