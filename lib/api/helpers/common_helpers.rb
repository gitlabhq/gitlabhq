module API
  module Helpers
    module CommonHelpers
      def convert_parameters_from_legacy_format(params)
        params.tap do |params|
          if params[:assignee_id].present?
            params[:assignee_ids] = [params.delete(:assignee_id)]
          end
        end
      end
    end
  end
end
