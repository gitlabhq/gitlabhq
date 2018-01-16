module API
  module Helpers
    module CommonHelpers
      def convert_parameters_from_legacy_format(params)
        params.tap do |params|
          assignee_id = params.delete(:assignee_id)

          if assignee_id.present?
            params[:assignee_ids] = [assignee_id]
          end
        end
      end
    end
  end
end
