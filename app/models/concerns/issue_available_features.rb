# frozen_string_literal: true

# Verifies features availability based on issue type.
# This can be used, for example, for hiding UI elements or blocking specific
# quick actions for particular issue types;
module IssueAvailableFeatures
  extend ActiveSupport::Concern

  class_methods do
    # EE only features are listed on EE::IssueAvailableFeatures
    def available_features_for_issue_types
      {
        assignee: %w(issue incident),
        confidentiality: %w(issue incident),
        time_tracking: %w(issue incident),
        move_and_clone: %w(issue incident)
      }.with_indifferent_access
    end
  end

  included do
    scope :with_feature, ->(feature) { where(issue_type: available_features_for_issue_types[feature]) }
  end

  def issue_type_supports?(feature)
    unless self.class.available_features_for_issue_types.has_key?(feature)
      raise ArgumentError, 'invalid feature'
    end

    type_for_issue = if Feature.enabled?(:issue_type_uses_work_item_types_table)
                       # The default will only be used in places where an issue is only build and not saved
                       work_item_type_with_default.base_type
                     else
                       issue_type
                     end

    self.class.available_features_for_issue_types[feature].include?(type_for_issue)
  end
end

IssueAvailableFeatures.prepend_mod_with('IssueAvailableFeatures')
IssueAvailableFeatures::ClassMethods.prepend_mod_with('IssueAvailableFeatures::ClassMethods')
