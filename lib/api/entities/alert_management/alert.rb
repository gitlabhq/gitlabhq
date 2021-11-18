# frozen_string_literal: true

module API
  module Entities
    module AlertManagement
      class Alert < Grape::Entity
        expose :iid
        expose :title
      end
    end
  end
end
