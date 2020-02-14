# frozen_string_literal: true

module API
  module Entities
    class Application < Grape::Entity
      expose :id
      expose :uid, as: :application_id
      expose :name, as: :application_name
      expose :redirect_uri, as: :callback_url
      expose :confidential
    end
  end
end
