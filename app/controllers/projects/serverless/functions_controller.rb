# frozen_string_literal: true

module Projects
  module Serverless
    class FunctionsController < Projects::ApplicationController
      include ProjectUnauthorized

      before_action :authorize_read_cluster!

      INDEX_PRIMING_INTERVAL = 10_000
      INDEX_POLLING_INTERVAL = 30_000

      def index
        finder = Projects::Serverless::FunctionsFinder.new(project.clusters)

        respond_to do |format|
          format.json do
            functions = finder.execute

            if functions.any?
              Gitlab::PollingInterval.set_header(response, interval: INDEX_POLLING_INTERVAL)
              render json: Projects::Serverless::ServiceSerializer.new(current_user: @current_user).represent(functions)
            else
              Gitlab::PollingInterval.set_header(response, interval: INDEX_PRIMING_INTERVAL)
              head :no_content
            end
          end

          format.html do
            @installed = finder.installed?
            render
          end
        end
      end
    end
  end
end
