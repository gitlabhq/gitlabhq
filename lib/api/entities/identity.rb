# frozen_string_literal: true

module API
  module Entities
    class Identity < Grape::Entity
      expose :provider, :extern_uid
    end
  end
end
