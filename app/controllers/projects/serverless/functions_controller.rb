# frozen_string_literal: true

module Projects
  module Serverless
    class FunctionsController < Projects::ApplicationController
      before_action :authorize_read_cluster!

      feature_category :serverless

      def index
        respond_to do |format|
          format.json do
            functions = finder.execute.select do |function|
              can?(@current_user, :read_cluster, function.cluster)
            end

            serialized_functions = serialize_function(functions)

            render json: {
              knative_installed: finder.knative_installed,
              functions: serialized_functions
            }.to_json
          end

          format.html do
            render
          end
        end
      end

      def show
        function = finder.service(params[:environment_id], params[:id])
        return not_found unless function && can?(@current_user, :read_cluster, function.cluster)

        @service = serialize_function(function)
        return not_found if @service.nil?

        @prometheus = finder.has_prometheus?(params[:environment_id])

        respond_to do |format|
          format.json do
            render json: @service
          end

          format.html
        end
      end

      def metrics
        respond_to do |format|
          format.json do
            metrics = finder.invocation_metrics(params[:environment_id], params[:id])

            if metrics.nil?
              head :no_content
            else
              render json: metrics
            end
          end
        end
      end

      private

      def finder
        Projects::Serverless::FunctionsFinder.new(project)
      end

      def serialize_function(function)
        Projects::Serverless::ServiceSerializer.new(current_user: @current_user, project: project).represent(function)
      end
    end
  end
end
