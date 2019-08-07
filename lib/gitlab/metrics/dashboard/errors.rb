# frozen_string_literal: true

# Central point for managing errors from within the metrics
# dashboard module. Handles errors from dashboard retrieval
# and processing steps, as well as defines shared error classes.
module Gitlab
  module Metrics
    module Dashboard
      module Errors
        PanelNotFoundError = Class.new(StandardError)

        PROCESSING_ERROR = Gitlab::Metrics::Dashboard::Stages::BaseStage::DashboardProcessingError
        NOT_FOUND_ERROR = Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError

        def handle_errors(error)
          case error
          when PROCESSING_ERROR
            error(error.message, :unprocessable_entity)
          when NOT_FOUND_ERROR
            error("#{dashboard_path} could not be found.", :not_found)
          when PanelNotFoundError
            error(error.message, :not_found)
          else
            raise error
          end
        end

        def panels_not_found!(opts)
          raise PanelNotFoundError.new("No panels matching properties #{opts}")
        end
      end
    end
  end
end
