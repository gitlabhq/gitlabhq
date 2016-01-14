class Spinach::Features::ProjectMergeRequestsReferences < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedIssuable
  include SharedNote
  include SharedProject
  include SharedUser
end
