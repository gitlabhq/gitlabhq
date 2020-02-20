# frozen_string_literal: true

module API
  module Entities
    class ExternalIssue < Grape::Entity
      expose :title
      expose :id
    end
  end
end
