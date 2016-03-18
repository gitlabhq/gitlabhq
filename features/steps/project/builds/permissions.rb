class Spinach::Features::ProjectBuildsPermissions < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedBuilds
  include SharedPaths
  include RepoHelpers
end
