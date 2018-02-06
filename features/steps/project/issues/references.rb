class Spinach::Features::ProjectIssuesReferences < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedIssuable
  include SharedNote
  include SharedProject
  include SharedUser
end
