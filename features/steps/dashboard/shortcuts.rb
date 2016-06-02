class Spinach::Features::DashboardShortcuts < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject
  include SharedSidebarActiveTab
  include SharedShortcuts
end
