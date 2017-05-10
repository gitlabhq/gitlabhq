module API
  module Helpers
    module CommonHelpers
      def convert_parameters_from_legacy_format(params)
        if params[:assignee_id].present?
          params[:assignee_ids] = [params.delete(:assignee_id)]
        end

        params
      end
    end
  end
end
