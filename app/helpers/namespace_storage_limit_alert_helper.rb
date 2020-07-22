# frozen_string_literal: true

module NamespaceStorageLimitAlertHelper
  # Overridden in EE
  def display_namespace_storage_limit_alert!
  end
end

NamespaceStorageLimitAlertHelper.prepend_if_ee('EE::NamespaceStorageLimitAlertHelper')
