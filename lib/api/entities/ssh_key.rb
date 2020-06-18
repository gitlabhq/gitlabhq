# frozen_string_literal: true

module API
  module Entities
    class SSHKey < Grape::Entity
      expose :id, :title, :created_at, :expires_at
      expose :publishable_key, as: :key
    end
  end
end
