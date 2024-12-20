# frozen_string_literal: true

module Banzai
  module Filter
    module References
      class FeatureFlagReferenceFilter < IssuableReferenceFilter
        self.reference_type = :feature_flag
        self.object_class   = Operations::FeatureFlag

        def object_sym
          :feature_flag
        end

        def parent_records(parent, ids)
          return Operations::FeatureFlag.none unless parent.is_a?(Project)

          parent.operations_feature_flags.where(iid: ids.to_a)
        end

        def url_for_object(feature_flag, project)
          ::Gitlab::Routing.url_helpers.edit_project_feature_flag_url(
            project,
            feature_flag.iid,
            only_path: context[:only_path]
          )
        end

        def object_link_title(object, matches)
          object.name
        end
      end
    end
  end
end
