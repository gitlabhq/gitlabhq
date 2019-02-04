# frozen_string_literal: true

module Projects
  module Serverless
    class FunctionsController < Projects::ApplicationController
      include ProjectUnauthorized

      before_action :authorize_read_cluster!

      INDEX_PRIMING_INTERVAL = 15_000
      INDEX_POLLING_INTERVAL = 60_000

      def index
        respond_to do |format|
          format.json do
            functions = finder.execute

            if functions.any?
              Gitlab::PollingInterval.set_header(response, interval: INDEX_POLLING_INTERVAL)
              render json: serialize_function(functions)
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

      def show
        @service = serialize_function(finder.service(params[:environment_id], params[:id]))
        return not_found if @service.nil?

        respond_to do |format|
          format.json do
            render json: @service
          end

          format.html
        end
      end

      private

      def finder
        Projects::Serverless::FunctionsFinder.new(project.clusters)
      end

      def serialize_function(function)
        Projects::Serverless::ServiceSerializer.new(current_user: @current_user, project: project).represent(function)
      end
    end
  end
end
