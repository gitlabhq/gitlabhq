# frozen_string_literal: true

module Gitlab
  module GlId
    def self.gl_id(actor)
      case actor
      when User
        "user-#{actor.id}"
      when DeployToken
        "deploy-token-#{actor.id}"
      else
        ''
      end
    end
  end
end
