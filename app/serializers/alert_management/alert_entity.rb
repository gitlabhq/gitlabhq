# frozen_string_literal: true

module AlertManagement
  class AlertEntity < Grape::Entity
    expose :iid
    expose :title
  end
end
