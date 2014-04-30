class CommentsOnCommits < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedNote
  include SharedPaths
  include SharedProject
  include SharedMarkdown
end
