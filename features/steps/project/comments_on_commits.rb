class Spinach::Features::CommentsOnCommits < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedNote
  include SharedPaths
  include SharedProject
end
