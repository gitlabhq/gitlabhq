# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Project
      class TreeSaver
        include DurationMeasuring

        attr_reader :full_path

        def initialize(project:, current_user:, shared:, params: {}, logger: Gitlab::Export::Logger)
          @params       = params
          @project      = project
          @current_user = current_user
          @shared       = shared
          @logger       = logger
        end

        def save
          with_duration_measuring do
            stream_export

            true
          end
        rescue StandardError => e
          @shared.error(e)
          false
        ensure
          json_writer&.close
        end

        private

        def stream_export
          on_retry = proc do |exception, try, elapsed_time, next_interval|
            @logger.info(
              message: "Project export retry triggered from streaming",
              'error.class': exception.class,
              'error.message': exception.message,
              try_count: try,
              elapsed_time_s: elapsed_time,
              wait_to_retry_s: next_interval,
              project_name: @project.name,
              project_id: @project.id
            )
          end

          serializer = ImportExport::Json::StreamingSerializer.new(
            exportable,
            reader.project_tree,
            json_writer,
            exportable_path: "project",
            logger: @logger,
            current_user: @current_user
          )

          Retriable.retriable(on: Net::OpenTimeout, on_retry: on_retry) do
            serializer.execute
          end
        end

        def reader
          @reader ||= Gitlab::ImportExport::Reader.new(shared: @shared)
        end

        def exportable
          @project.present(**exportable_params)
        end

        def exportable_params
          params = {
            presenter_class: presenter_class,
            current_user: @current_user
          }
          params[:override_description] = @params[:description] if @params[:description].present?
          params
        end

        def presenter_class
          Projects::ImportExport::ProjectExportPresenter
        end

        def json_writer
          @json_writer ||= begin
            full_path = File.join(@shared.export_path, 'tree')
            Gitlab::ImportExport::Json::NdjsonWriter.new(full_path)
          end
        end
      end
    end
  end
end
