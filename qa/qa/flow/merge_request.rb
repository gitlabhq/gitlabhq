# frozen_string_literal: true

module QA
  module Flow
    module MergeRequest
      module_function

      def enable_merge_trains
        Page::Project::Menu.perform(&:go_to_general_settings)
        Page::Project::Settings::Main.perform(&:expand_merge_requests_settings)
        Page::Project::Settings::MergeRequest.perform(&:enable_merge_train)
      end
    end
  end
end
