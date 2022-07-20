# frozen_string_literal: true

module Gitlab
  module ErrorTracking
    class ErrorRepository
      class ActiveRecordStrategy
        def initialize(project)
          @project = project
        end

        def report_error(
          name:, description:, actor:, platform:,
          environment:, level:, occurred_at:, payload:
        )
          error = project_errors.report_error(
            name: name,                # Example: ActionView::MissingTemplate
            description: description,  # Example: Missing template posts/show in...
            actor: actor,              # Example: PostsController#show
            platform: platform,        # Example: ruby
            timestamp: occurred_at
          )

          # The payload field contains all the data on error including stacktrace in jsonb.
          # Together with occurred_at these are 2 main attributes that we need to save here.
          error.events.create!(
            environment: environment,
            description: description,
            level: level,
            occurred_at: occurred_at,
            payload: payload
          )
        rescue ActiveRecord::ActiveRecordError => e
          handle_exceptions(e)
        end

        def find_error(id)
          project_error(id).to_sentry_detailed_error
        rescue ActiveRecord::ActiveRecordError => e
          handle_exceptions(e)
        end

        def list_errors(filters:, query:, sort:, limit:, cursor:)
          errors = project_errors
          errors = filter_by_status(errors, filters[:status])
          errors = sort(errors, sort)
          errors = errors.keyset_paginate(cursor: cursor, per_page: limit)
          # query is not supported

          pagination = ErrorRepository::Pagination.new(errors.cursor_for_next_page, errors.cursor_for_previous_page)

          [errors.map(&:to_sentry_error), pagination]
        end

        def last_event_for(id)
          project_error(id).last_event&.to_sentry_error_event
        rescue ActiveRecord::ActiveRecordError => e
          handle_exceptions(e)
        end

        def update_error(id, **attributes)
          project_error(id).update(attributes)
        end

        def dsn_url(public_key)
          gitlab = Settings.gitlab

          custom_port = Settings.gitlab_on_standard_port? ? nil : ":#{gitlab.port}"

          base_url = [
            gitlab.protocol,
            "://",
            public_key,
            '@',
            gitlab.host,
            custom_port,
            gitlab.relative_url_root
          ].join('')

          "#{base_url}/api/v4/error_tracking/collector/#{project.id}"
        end

        private

        attr_reader :project

        def project_errors
          ::ErrorTracking::Error.where(project: project) # rubocop:disable CodeReuse/ActiveRecord
        end

        def project_error(id)
          project_errors.find(id)
        end

        def filter_by_status(errors, status)
          return errors unless ::ErrorTracking::Error.statuses.key?(status)

          errors.for_status(status)
        end

        def sort(errors, sort)
          return errors.order_id_desc unless sort

          errors.sort_by_attribute(sort)
        end

        def handle_exceptions(exception)
          case exception
          when ActiveRecord::RecordInvalid
            raise RecordInvalidError, exception.message
          else
            raise DatabaseError, exception.message
          end
        end
      end
    end
  end
end
