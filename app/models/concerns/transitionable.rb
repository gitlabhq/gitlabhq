# frozen_string_literal: true

module Transitionable
  extend ActiveSupport::Concern

  attr_accessor :transitioning

  def transitioning?
    return false unless transitioning && Feature.enabled?(:skip_validations_during_transitions, project)

    true
  end

  def enable_transitioning
    self.transitioning = true
  end

  def disable_transitioning
    self.transitioning = false
  end
end
