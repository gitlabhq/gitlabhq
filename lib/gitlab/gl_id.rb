module Gitlab
  module GlId
    def self.gl_id(user)
      if user.present?
        gl_id_from_id_value(user.id)
      else
        ''
      end
    end

    def self.gl_id_from_id_value(id)
      "user-#{id}"
    end
  end
end
