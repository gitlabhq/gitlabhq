# frozen_string_literal: true

module GemExtensions
  module ActiveRecord
    module Associations
      module HasManyThroughAssociation
        extend ActiveSupport::Concern

        def find_target
          return [] unless target_reflection_has_associated_record?
          return scope.to_a if disable_joins

          super
        end
      end
    end
  end
end
