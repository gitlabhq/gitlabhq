module ProtectedEnvironmentsHelper
  def protected_environments_enabled?(project)
    project.protected_environments_feature_available?
  end
end
