# frozen_string_literal: true

module Clusters
  module Concerns
    module ApplicationVersion
      extend ActiveSupport::Concern

      included do
        state_machine :status do
          before_transition any => [:installed, :updated] do |application|
            application.version = application.class.const_get(:VERSION, false)
          end
        end
      end

      def update_available?
        version != self.class.const_get(:VERSION, false)
      end
    end
  end
end
