module ProtectedEnvironmentsHelper
  def protected_environments_enabled?
    Feature.enabled?('protected_environments')
  end
end
