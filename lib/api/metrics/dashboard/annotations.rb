# frozen_string_literal: true

module API
  module Metrics
    module Dashboard
      class Annotations < ::API::Base
        feature_category :metrics
        urgency :low

        desc 'Create a new annotation' do
          detail 'Creates a new monitoring dashboard annotation'
          success Entities::Metrics::Dashboard::Annotation
          failure [
            { code: 400, message: 'Bad Request' },
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not Found' }
          ]
          tags %w[dashboard_annotations]
        end

        ANNOTATIONS_SOURCES = [
          { class: ::Environment, resource: :environments, create_service_param_key: :environment },
          { class: ::Clusters::Cluster, resource: :clusters, create_service_param_key: :cluster }
        ].freeze

        ANNOTATIONS_SOURCES.each do |annotations_source|
          resource annotations_source[:resource] do
            params do
              requires :starting_at, type: DateTime,
                                     desc: 'Date time string, ISO 8601 formatted, such as 2016-03-11T03:45:40Z.'\
                                      'Timestamp marking start point of annotation.'
              optional :ending_at, type: DateTime,
                                   desc: 'Date time string, ISO 8601 formatted, such as 2016-03-11T03:45:40Z.'\
                                    'Timestamp marking end point of annotation.'\
                                    'When not supplied, an annotation displays as a single event at the start point.'
              requires :dashboard_path, type: String, coerce_with: -> (val) { CGI.unescape(val) },
                                        desc: 'ID of the dashboard which needs to be annotated.'\
                                          'Treated as a CGI-escaped path, and automatically un-escaped.'
              requires :description, type: String, desc: 'Description of the annotation.'
            end

            post ':id/metrics_dashboard/annotations' do
              not_found! if Feature.enabled?(:remove_monitor_metrics)

              annotations_source_object = annotations_source[:class].find(params[:id])

              forbidden! unless can?(current_user, :admin_metrics_dashboard_annotation, annotations_source_object)

              create_service_params = declared(params).merge(
                annotations_source[:create_service_param_key] => annotations_source_object
              )

              result = ::Metrics::Dashboard::Annotations::CreateService.new(current_user, create_service_params).execute

              if result[:status] == :success
                present result[:annotation], with: Entities::Metrics::Dashboard::Annotation
              else
                error!(result, 400)
              end
            end
          end
        end
      end
    end
  end
end
