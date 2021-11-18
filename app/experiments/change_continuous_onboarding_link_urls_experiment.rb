# frozen_string_literal: true

class ChangeContinuousOnboardingLinkUrlsExperiment < ApplicationExperiment # rubocop:disable Gitlab/NamespacedClass
  attr_writer :namespace

  def track(action, **event_args)
    super(action, **event_args.merge(namespace: @namespace))
  end
end
