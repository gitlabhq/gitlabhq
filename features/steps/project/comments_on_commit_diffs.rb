class Spinach::Features::CommentsOnCommitDiffs < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedDiffNote
  include SharedPaths
  include SharedProject
end
