# frozen_string_literal: true

module API
  module Entities
    class Identity < Grape::Entity
      expose :provider, :extern_uid
    end
  end
end

API::Entities::Identity.prepend_mod_with('API::Entities::Identity')
