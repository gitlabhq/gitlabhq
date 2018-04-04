module Gitlab
  module GlId
    def self.gl_id(user)
      gl_id_from_id_value(user&.id)
    end

    def self.gl_id_from_id_value(id)
      if id.present?
        "user-#{id}"
      else
        ""
      end
    end
  end
end
