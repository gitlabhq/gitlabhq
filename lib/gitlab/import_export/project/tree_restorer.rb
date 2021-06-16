# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Project
      class TreeRestorer
        include Gitlab::Utils::StrongMemoize

        attr_reader :user
        attr_reader :shared
        attr_reader :project

        def initialize(user:, shared:, project:)
          @user = user
          @shared = shared
          @project = project
        end

        def restore
          unless relation_reader
            raise Gitlab::ImportExport::Error, 'invalid import format'
          end

          @project_attributes = relation_reader.consume_attributes(importable_path)
          @project_members = relation_reader.consume_relation(importable_path, 'project_members')
            .map(&:first)

          # ensure users are mapped before tree restoration
          # so that even if there is no content to associate
          # users with, they are still added to the project
          members_mapper.map

          if relation_tree_restorer.restore
            import_failure_service.with_retry(action: 'set_latest_merge_request_diff_ids!') do
              @project.merge_requests.set_latest_merge_request_diff_ids!
            end

            true
          else
            false
          end
        rescue StandardError => e
          @shared.error(e)
          false
        end

        private

        def relation_reader
          strong_memoize(:relation_reader) do
            [ndjson_relation_reader, legacy_relation_reader]
              .compact.find(&:exist?)
          end
        end

        def ndjson_relation_reader
          return unless Feature.enabled?(:project_import_ndjson, project.namespace, default_enabled: true)

          ImportExport::Json::NdjsonReader.new(
            File.join(shared.export_path, 'tree')
          )
        end

        def legacy_relation_reader
          ImportExport::Json::LegacyReader::File.new(
            File.join(shared.export_path, 'project.json'),
            relation_names: reader.project_relation_names,
            allowed_path: importable_path
          )
        end

        def relation_tree_restorer
          @relation_tree_restorer ||= relation_tree_restorer_class.new(
            user: @user,
            shared: @shared,
            relation_reader: relation_reader,
            object_builder: object_builder,
            members_mapper: members_mapper,
            relation_factory: relation_factory,
            reader: reader,
            importable: @project,
            importable_attributes: @project_attributes,
            importable_path: importable_path
          )
        end

        def relation_tree_restorer_class
          RelationTreeRestorer
        end

        def members_mapper
          @members_mapper ||= Gitlab::ImportExport::MembersMapper.new(exported_members: @project_members,
                                                                      user: @user,
                                                                      importable: @project)
        end

        def object_builder
          Project::ObjectBuilder
        end

        def relation_factory
          Project::RelationFactory
        end

        def reader
          @reader ||= Gitlab::ImportExport::Reader.new(shared: @shared)
        end

        def import_failure_service
          @import_failure_service ||= ImportFailureService.new(@project)
        end

        def importable_path
          "project"
        end
      end
    end
  end
end
