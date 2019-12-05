# frozen_string_literal: true

module Gitlab
  module ImportExport
    class ProjectTreeRestorer
      # Relations which cannot be saved at project level (and have a group assigned)
      GROUP_MODELS = [GroupLabel, Milestone].freeze

      attr_reader :user
      attr_reader :shared
      attr_reader :project

      def initialize(user:, shared:, project:)
        @path = File.join(shared.export_path, 'project.json')
        @user = user
        @shared = shared
        @project = project
      end

      def restore
        begin
          @tree_hash = read_tree_hash
        rescue => e
          Rails.logger.error("Import/Export error: #{e.message}") # rubocop:disable Gitlab/RailsLogger
          raise Gitlab::ImportExport::Error.new('Incorrect JSON format')
        end

        @project_members = @tree_hash.delete('project_members')

        RelationRenameService.rename(@tree_hash)

        ActiveRecord::Base.uncached do
          ActiveRecord::Base.no_touching do
            update_project_params!
            create_project_relations!
            post_import!
          end
        end

        # ensure that we have latest version of the restore
        @project.reload # rubocop:disable Cop/ActiveRecordAssociationReload

        true
      rescue => e
        @shared.error(e)
        false
      end

      private

      def read_tree_hash
        json = IO.read(@path)
        ActiveSupport::JSON.decode(json)
      end

      def members_mapper
        @members_mapper ||= Gitlab::ImportExport::MembersMapper.new(exported_members: @project_members,
                                                                    user: @user,
                                                                    project: @project)
      end

      # A Hash of the imported merge request ID -> imported ID.
      def merge_requests_mapping
        @merge_requests_mapping ||= {}
      end

      # Loops through the tree of models defined in import_export.yml and
      # finds them in the imported JSON so they can be instantiated and saved
      # in the DB. The structure and relationships between models are guessed from
      # the configuration yaml file too.
      # Finally, it updates each attribute in the newly imported project.
      def create_project_relations!
        project_relations.each(&method(
          :process_project_relation!))
      end

      def post_import!
        @project.merge_requests.set_latest_merge_request_diff_ids!
      end

      def process_project_relation!(relation_key, relation_definition)
        data_hashes = @tree_hash.delete(relation_key)
        return unless data_hashes

        # we do not care if we process array or hash
        data_hashes = [data_hashes] unless data_hashes.is_a?(Array)

        relation_index = 0

        # consume and remove objects from memory
        while data_hash = data_hashes.shift
          process_project_relation_item!(relation_key, relation_definition, relation_index, data_hash)
          relation_index += 1
        end
      end

      def process_project_relation_item!(relation_key, relation_definition, relation_index, data_hash)
        relation_object = build_relation(relation_key, relation_definition, data_hash)
        return unless relation_object
        return if group_model?(relation_object)

        relation_object.project = @project
        relation_object.save!

        save_id_mapping(relation_key, data_hash, relation_object)
      rescue => e
        # re-raise if not enabled
        raise e unless Feature.enabled?(:import_graceful_failures, @project.group, default_enabled: true)

        log_import_failure(relation_key, relation_index, e)
      end

      def log_import_failure(relation_key, relation_index, exception)
        Gitlab::Sentry.track_acceptable_exception(exception,
          extra: { project_id: @project.id, relation_key: relation_key, relation_index: relation_index })

        ImportFailure.create(
          project: @project,
          relation_key: relation_key,
          relation_index: relation_index,
          exception_class: exception.class.to_s,
          exception_message: exception.message.truncate(255),
          correlation_id_value: Labkit::Correlation::CorrelationId.current_id
        )
      end

      # Older, serialized CI pipeline exports may only have a
      # merge_request_id and not the full hash of the merge request. To
      # import these pipelines, we need to preserve the mapping between
      # the old and new the merge request ID.
      def save_id_mapping(relation_key, data_hash, relation_object)
        return unless relation_key == 'merge_requests'

        merge_requests_mapping[data_hash['id']] = relation_object.id
      end

      def project_relations
        @project_relations ||=
          reader
            .attributes_finder
            .find_relations_tree(:project)
            .deep_stringify_keys
      end

      def update_project_params!
        project_params = @tree_hash.reject do |key, value|
          project_relations.include?(key)
        end

        project_params = project_params.merge(
          present_project_override_params)

        # Cleaning all imported and overridden params
        project_params = Gitlab::ImportExport::AttributeCleaner.clean(
          relation_hash: project_params,
          relation_class: Project,
          excluded_keys: excluded_keys_for_relation(:project))

        @project.assign_attributes(project_params)
        @project.drop_visibility_level!

        Gitlab::Timeless.timeless(@project) do
          @project.save!
        end
      end

      def present_project_override_params
        # we filter out the empty strings from the overrides
        # keeping the default values configured
        project_override_params.transform_values do |value|
          value.is_a?(String) ? value.presence : value
        end.compact
      end

      def project_override_params
        @project_override_params ||= @project.import_data&.data&.fetch('override_params', nil) || {}
      end

      def build_relations(relation_key, relation_definition, data_hashes)
        data_hashes.map do |data_hash|
          build_relation(relation_key, relation_definition, data_hash)
        end.compact
      end

      def build_relation(relation_key, relation_definition, data_hash)
        # TODO: This is hack to not create relation for the author
        # Rather make `RelationFactory#set_note_author` to take care of that
        return data_hash if relation_key == 'author'

        # create relation objects recursively for all sub-objects
        relation_definition.each do |sub_relation_key, sub_relation_definition|
          transform_sub_relations!(data_hash, sub_relation_key, sub_relation_definition)
        end

        Gitlab::ImportExport::RelationFactory.create(
          relation_sym: relation_key.to_sym,
          relation_hash: data_hash,
          members_mapper: members_mapper,
          merge_requests_mapping: merge_requests_mapping,
          user: @user,
          project: @project,
          excluded_keys: excluded_keys_for_relation(relation_key))
      end

      def transform_sub_relations!(data_hash, sub_relation_key, sub_relation_definition)
        sub_data_hash = data_hash[sub_relation_key]
        return unless sub_data_hash

        # if object is a hash we can create simple object
        # as it means that this is 1-to-1 vs 1-to-many
        sub_data_hash =
          if sub_data_hash.is_a?(Array)
            build_relations(
              sub_relation_key,
              sub_relation_definition,
              sub_data_hash).presence
          else
            build_relation(
              sub_relation_key,
              sub_relation_definition,
              sub_data_hash)
          end

        # persist object(s) or delete from relation
        if sub_data_hash
          data_hash[sub_relation_key] = sub_data_hash
        else
          data_hash.delete(sub_relation_key)
        end
      end

      def group_model?(relation_object)
        GROUP_MODELS.include?(relation_object.class) && relation_object.group_id
      end

      def reader
        @reader ||= Gitlab::ImportExport::Reader.new(shared: @shared)
      end

      def excluded_keys_for_relation(relation)
        reader.attributes_finder.find_excluded_keys(relation)
      end
    end
  end
end
