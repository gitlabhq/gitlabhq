# frozen_string_literal: true

module GemExtensions
  module ActiveRecord
    module Associations
      module HasOneThroughAssociation
        extend ActiveSupport::Concern

        def find_target
          return scope.first if disable_joins

          super
        end
      end
    end
  end
end
