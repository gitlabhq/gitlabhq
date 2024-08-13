# frozen_string_literal: true

module Ci
  module HidableVariable
    extend ActiveSupport::Concern

    included do
      validates :hidden, inclusion: { in: [true, false] }
      validate :validate_masked_and_hidden_on_create, on: :create
      validate :validate_masked_and_hidden_on_update, on: :update
    end

    private

    def validate_masked_and_hidden_on_create
      return if hidden_variables_feature_flag_is_disabled?
      return unless masked == false && hidden == true

      errors.add(:masked, 'should be true when variable is hidden')
    end

    def validate_masked_and_hidden_on_update
      return if hidden_variables_feature_flag_is_disabled?
      return if !masked_changed? && !hidden_changed?
      return if hidden == false && !hidden_changed?

      if hidden_changed?
        errors.add(:base, 'Updating hidden attribute is not allowed on updates.')
      else
        errors.add(:base, 'Updating masked attribute is not allowed on updates for hidden variables.')
      end
    end

    # This logic will go away on the ff `ci_hidden_variables` deprecation
    def hidden_variables_feature_flag_is_disabled?
      parent = if is_a?(Ci::Variable)
                 project&.root_ancestor
               elsif is_a?(Ci::GroupVariable)
                 group
               end

      return true unless parent

      ::Feature.disabled?(:ci_hidden_variables, parent)
    end
  end
end
