# frozen_string_literal: true

module API
  module Entities
    class DeployKey < Entities::SSHKey
      expose :key
    end
  end
end
