# frozen_string_literal: true

module Gitlab
  module ExceptionLogFormatter
    class << self
      def format!(exception, payload)
        return unless exception

        # Elasticsearch/Fluentd don't handle nested structures well.
        # Use periods to flatten the fields.
        payload.merge!(
          'exception.class' => exception.class.name,
          'exception.message' => sanitize_message(exception)
        )

        if exception.backtrace
          payload['exception.backtrace'] = Rails.backtrace_cleaner.clean(exception.backtrace)
        end

        if exception.cause
          payload['exception.cause_class'] = exception.cause.class.name
        end

        if gitaly_metadata = find_gitaly_metadata(exception)
          payload['exception.gitaly'] = gitaly_metadata.to_s
        end

        if sql = find_sql(exception)
          payload['exception.sql'] = sql
        end
      end

      def find_sql(exception)
        if exception.is_a?(ActiveRecord::StatementInvalid)
          # StatementInvalid may be caused by a statement timeout or a bad query
          normalize_query(exception.sql.to_s)
        elsif exception.cause.present?
          find_sql(exception.cause)
        end
      end

      def find_gitaly_metadata(exception)
        if exception.is_a?(::Gitlab::Git::BaseError)
          exception.metadata
        elsif exception.is_a?(::GRPC::BadStatus)
          exception.metadata[::Gitlab::Git::BaseError::METADATA_KEY]
        elsif exception.cause.present?
          find_gitaly_metadata(exception.cause)
        end
      end

      private

      def normalize_query(sql)
        PgQuery.normalize(sql)
      rescue PgQuery::ParseError
        sql
      end

      def sanitize_message(exception)
        Gitlab::Sanitizers::ExceptionMessage.clean(exception.class.name, exception.message)
      end
    end
  end
end
