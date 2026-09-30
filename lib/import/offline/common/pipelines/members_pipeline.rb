# frozen_string_literal: true

module Import
  module Offline
    module Common
      module Pipelines
        class MembersPipeline < ::BulkImports::Common::Pipelines::MembersPipeline
          file_extraction_pipeline!

          relation_name 'members'

          extractor ::BulkImports::Common::Extractors::NdjsonExtractor, relation: relation

          # Pipeline class attributes are per-class, so retain the base member transformers.
          def self.transformers
            superclass.transformers
          end

          def extract(context)
            file_extractor.extract(context)
          end

          def transform(context, data)
            member, = data
            return unless member

            user = member['user']
            return unless user && user['id']

            member['access_level'] = { 'integer_value' => member['access_level'] }
            user['user_gid'] = "gid://gitlab/User/#{user['id']}"
            member['source_xid'] = context.source_xid
            member['entity_type'] = context.entity_type

            member
          end

          def after_run(_context)
            file_extractor.remove_tmpdir
          end

          private

          def file_extractor
            @file_extractor ||= instantiate(self.class.get_extractor)
          end
        end
      end
    end
  end
end
