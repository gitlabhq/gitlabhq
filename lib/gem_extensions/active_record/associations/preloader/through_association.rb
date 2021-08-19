# frozen_string_literal: true

module GemExtensions
  module ActiveRecord
    module Associations
      module Preloader
        module ThroughAssociation
          extend ActiveSupport::Concern

          def through_scope
            scope = through_reflection.klass.unscoped
            options = reflection.options

            return scope if options[:disable_joins]

            super
          end
        end
      end
    end
  end
end
