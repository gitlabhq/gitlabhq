# frozen_string_literal: true

module Clusters
  module Concerns
    module ApplicationVersion
      extend ActiveSupport::Concern

      included do
        state_machine :status do
          after_transition any => [:installing] do |application|
            application.update(version: application.class.const_get(:VERSION))
          end
        end
      end
    end
  end
end
