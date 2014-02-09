class CommentsOnCommitDiffs < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedDiffNote
  include SharedMarkdown
  include SharedPaths
  include SharedProject
end
