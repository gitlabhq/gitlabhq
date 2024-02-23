# frozen_string_literal: true

module FeatureGate
  extend ActiveSupport::Concern

  class_methods do
    def actor_from_id(model_id)
      ::Feature::ActorWrapper.new(self, model_id)
    end
  end

  def flipper_id
    return if new_record?

    # rubocop:disable Gitlab/ModuleWithInstanceVariables -- Memoization is an acceptable use of instance variable assignment
    @flipper_id ||= self.class.actor_from_id(id).flipper_id
    # rubocop:enable Gitlab/ModuleWithInstanceVariables
  end
end
