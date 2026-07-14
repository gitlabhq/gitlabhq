# frozen_string_literal: true

module Import
  module Offline
    module Common
      module Pipelines
        class UserContributionsPipeline
          include ::BulkImports::Pipeline
          include ::BulkImports::Pipeline::HexdigestCacheStrategy

          file_extraction_pipeline!

          relation_name ::BulkImports::FileTransfer::BaseConfig::USER_CONTRIBUTIONS_RELATION

          extractor ::BulkImports::Common::Extractors::NdjsonExtractor, relation: relation

          def transform(_context, data)
            record = data&.first
            return unless record

            # The identifier is cast to a string to keep SourceUserMapper
            # lookups (and its internal cache keys) consistent with other
            # pipelines, regardless of how the id was serialized in the export.
            record.merge('id' => record['id'].to_s)
          end

          def load(context, data)
            return unless data

            source_user_identifier = data['id']
            return log_missing_identifier if source_user_identifier.blank?

            source_user = context.source_user_mapper.find_source_user(source_user_identifier)
            return log_missing_source_user(source_user_identifier) unless source_user

            params = {
              source_name: data['name'],
              source_username: data['username']
            }.compact

            return log_empty_params(source_user) if params.empty?

            result = ::Import::SourceUsers::UpdateService.new(source_user, params).execute
            return if result.success?

            log_failed_update(source_user, result)
          end

          def after_run(_context)
            extractor.remove_tmpdir
          end

          private

          def log_missing_identifier
            warn(message: 'Missing source user identifier')
          end

          def log_missing_source_user(identifier)
            warn(
              message: 'Source user not found',
              source_user_identifier: identifier
            )
          end

          def log_empty_params(source_user)
            warn(
              message: 'Missing source user information',
              source_user_id: source_user.id
            )
          end

          def log_failed_update(source_user, result)
            warn(
              message: 'Failed to update source user',
              source_user_id: source_user.id,
              Labkit::Fields::ERROR_MESSAGE => result.message
            )
          end
        end
      end
    end
  end
end
