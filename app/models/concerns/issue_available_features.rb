# frozen_string_literal: true

# Verifies features availability based on issue type.
# This can be used, for example, for hiding UI elements or blocking specific
# quick actions for particular issue types;
module IssueAvailableFeatures
  extend ActiveSupport::Concern

  # EE only features are listed on EE::IssueAvailableFeatures
  def available_features_for_issue_types
    {}.with_indifferent_access
  end

  def issue_type_supports?(feature)
    unless available_features_for_issue_types.has_key?(feature)
      raise ArgumentError, 'invalid feature'
    end

    available_features_for_issue_types[feature].include?(issue_type)
  end
end

IssueAvailableFeatures.prepend_if_ee('EE::IssueAvailableFeatures')
