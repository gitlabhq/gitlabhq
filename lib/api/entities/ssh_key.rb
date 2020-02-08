# frozen_string_literal: true

module API
  module Entities
    class SSHKey < Grape::Entity
      expose :id, :title, :key, :created_at
    end
  end
end
