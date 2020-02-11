# frozen_string_literal: true

module API
  module Entities
    class PushEventPayload < Grape::Entity
      expose :commit_count, :action, :ref_type, :commit_from, :commit_to, :ref,
             :commit_title, :ref_count
    end
  end
end
