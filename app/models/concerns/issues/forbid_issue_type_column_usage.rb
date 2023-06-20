# frozen_string_literal: true

# TODO: Remove with https://gitlab.com/gitlab-org/gitlab/-/issues/402699
module Issues
  module ForbidIssueTypeColumnUsage
    extend ActiveSupport::Concern

    ForbiddenColumnUsed = Class.new(StandardError)

    included do
      WorkItems::Type.base_types.each do |base_type, _value|
        define_method "#{base_type}?".to_sym do
          error_message = <<~ERROR
            `#{model_name.element}.#{base_type}?` uses the `issue_type` column underneath. As we want to remove the column,
            its usage is forbidden. You should use the `work_item_types` table instead.

            # Before

            #{model_name.element}.#{base_type}? => true

            # After

            #{model_name.element}.work_item_type.#{base_type}? => true

            More details in https://gitlab.com/groups/gitlab-org/-/epics/10529
          ERROR

          raise ForbiddenColumnUsed, error_message
        end

        define_singleton_method base_type.to_sym do
          error = ForbiddenColumnUsed.new(
            <<~ERROR
              `#{name}.#{base_type}` uses the `issue_type` column underneath. As we want to remove the column,
              its usage is forbidden. You should use the `work_item_types` table instead.

              # Before

              #{name}.#{base_type}

              # After

              #{name}.with_issue_type(:#{base_type})

              More details in https://gitlab.com/groups/gitlab-org/-/epics/10529
            ERROR
          )

          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
            error,
            method_name: "#{name}.#{base_type}"
          )

          with_issue_type(base_type.to_sym)
        end
      end
    end
  end
end
