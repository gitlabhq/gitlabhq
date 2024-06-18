# frozen_string_literal: true

module RemoteDevelopment
  module Settings
    # This module contains all messages for the Remote Development Settings sub-domain, both errors and domain events.
    # Note that we intentionally have not DRY'd up the declaration of the subclasses with loops and
    # metaprogramming, because we want the types to be easily indexable and navigable within IDEs.
    module Messages
      #---------------------------------------------------------------
      # Errors - message name should describe the reason for the error
      #---------------------------------------------------------------

      SettingsCurrentSettingsReadFailed = Class.new(Message)
      SettingsEnvironmentVariableReadFailed = Class.new(Message)
      SettingsVscodeExtensionsGalleryValidationFailed = Class.new(Message)
      SettingsVscodeExtensionsGalleryMetadataValidationFailed = Class.new(Message)
      SettingsFullReconciliationIntervalSecondsValidationFailed = Class.new(Message)
      SettingsPartialReconciliationIntervalSecondsValidationFailed = Class.new(Message)

      #---------------------------------------------------------
      # Domain Events - message name should describe the outcome
      #---------------------------------------------------------

      SettingsGetSuccessful = Class.new(Message)
    end
  end
end
