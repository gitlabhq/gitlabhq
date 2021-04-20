# frozen_string_literal: true

module API
  module Entities
    class NamespaceExistence < Grape::Entity
      expose :exists, :suggests
    end
  end
end
