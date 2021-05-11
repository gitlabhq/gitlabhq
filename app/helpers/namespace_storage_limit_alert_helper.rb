# frozen_string_literal: true

module NamespaceStorageLimitAlertHelper
  # Overridden in EE
  def display_namespace_storage_limit_alert!
  end
end

NamespaceStorageLimitAlertHelper.prepend_mod_with('NamespaceStorageLimitAlertHelper')
