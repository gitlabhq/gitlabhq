# frozen_string_literal: true

module API
  module Entities
    class SSHKey < Grape::Entity
      expose :id, :title, :key, :created_at, :expires_at
    end
  end
end
