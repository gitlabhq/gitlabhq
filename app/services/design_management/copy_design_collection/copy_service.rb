# frozen_string_literal: true

# Service to copy a DesignCollection from one Issue to another.
# Copies the DesignCollection's Designs, Versions, and Notes on Designs.
module DesignManagement
  module CopyDesignCollection
    class CopyService < DesignService
      # rubocop: disable CodeReuse/ActiveRecord
      def initialize(project, user, params = {})
        super

        @target_issue = params.fetch(:target_issue)
        @target_project = @target_issue.project
        @target_repository = @target_project.design_repository
        @target_design_collection = @target_issue.design_collection
        @temporary_branch = "CopyDesignCollectionService_#{SecureRandom.hex}"
        # The user who triggered the copy may not have permissions to push
        # to the design repository.
        @git_user = @target_project.first_owner

        @designs = DesignManagement::Design.unscoped.where(issue: issue).order(:id).load
        @versions = DesignManagement::Version.unscoped.where(issue: issue).order(:id).includes(:designs).load

        @sha_attribute = Gitlab::Database::ShaAttribute.new
        @shas = []
        @event_enum_map = DesignManagement::DesignAction::EVENT_FOR_GITALY_ACTION.invert
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def execute
        return error('User cannot copy design collection to issue') unless user_can_copy?
        return error('Target design collection must first be queued') unless target_design_collection.copy_in_progress?
        return error('Design collection has no designs') if designs.empty?
        return error('Target design collection already has designs') unless target_design_collection.empty?

        with_temporary_branch do
          copy_commits!

          ApplicationRecord.transaction do
            design_ids = copy_designs!
            version_ids = copy_versions!
            copy_actions!(design_ids, version_ids)
            link_lfs_files!
            copy_notes!(design_ids)
            finalize!
          end
        end

        ServiceResponse.success
      rescue Gitlab::Git::CommandError => ex
        error(message: ex.message)
      rescue StandardError => error
        log_exception(error)

        target_design_collection.error_copy!

        error('Designs were unable to be copied successfully')
      end

      private

      attr_reader :designs, :event_enum_map, :git_user, :sha_attribute, :shas,
        :temporary_branch, :target_design_collection, :target_issue,
        :target_repository, :target_project, :versions

      alias_method :merge_branch, :target_branch

      def log_exception(exception)
        payload = {
          issue_id: issue.id,
          project_id: project.id,
          target_issue_id: target_issue.id,
          target_project: target_project.id
        }

        Gitlab::ErrorTracking.track_exception(exception, payload)
      end

      def error(message)
        ServiceResponse.error(message: message)
      end

      def user_can_copy?
        current_user.can?(:read_design, design_collection) &&
          current_user.can?(:admin_issue, target_issue)
      end

      def with_temporary_branch(&block)
        target_repository.create_if_not_exists

        create_default_branch! if target_repository.empty?
        create_temporary_branch!

        yield
      ensure
        remove_temporary_branch!
      end

      # A project that does not have any designs will have a blank design
      # repository. To create a temporary branch from default branch we need to
      # create default branch first by adding a file to it.
      def create_default_branch!
        target_repository.create_file(
          git_user,
          ".CopyDesignCollectionService_#{Time.now.to_i}",
          '.gitlab',
          message: "Commit to create #{merge_branch} branch in CopyDesignCollectionService",
          branch_name: merge_branch
        )
      end

      def create_temporary_branch!
        target_repository.add_branch(
          git_user,
          temporary_branch,
          target_repository.root_ref
        )
      end

      def remove_temporary_branch!
        return unless target_repository.branch_exists?(temporary_branch)

        target_sha = target_repository.commit(temporary_branch).id

        target_repository.rm_branch(git_user, temporary_branch, target_sha: target_sha)
      end

      # Merge the temporary branch containing the commits to default branch
      # and update the state of the target_design_collection.
      def finalize!
        source_sha = shas.last

        target_repository.raw.merge(
          git_user,
          source_sha: source_sha,
          target_branch: merge_branch,
          message: 'CopyDesignCollectionService finalize merge'
        ) { nil }

        target_design_collection.end_copy!
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def copy_commits!
        # Execute another query to include actions and their designs
        DesignManagement::Version.unscoped.where(id: versions).order(:id).includes(actions: :design).find_each(batch_size: 100) do |version|
          gitaly_actions = version.actions.map do |action|
            design = action.design
            # Map the raw Action#event enum value to a Gitaly "action" for the
            # `Repository#commit_files` call.
            gitaly_action_name = @event_enum_map[action.event_before_type_cast]
            # `content` will be the LfsPointer file and not the design file,
            # and can be nil for deletions.
            content = blobs.dig(version.sha, design.filename)&.data
            file_path = DesignManagement::Design.build_full_path(target_issue, design)

            {
              action: gitaly_action_name,
              file_path: file_path,
              content: content
            }.compact
          end

          sha = target_repository.commit_files(
            git_user,
            branch_name: temporary_branch,
            message: commit_message(version),
            actions: gitaly_actions
          )

          shas << sha
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def copy_designs!
        design_attributes = attributes_config[:design_attributes]

        DesignManagement::Design.with_project_iid_supply(target_project) do |supply|
          new_rows = designs.each_with_index.map do |design, i|
            design.attributes.slice(*design_attributes).merge(
              issue_id: target_issue.id,
              project_id: target_project.id,
              iid: supply.next_value
            )
          end

          # TODO Replace `ApplicationRecord.legacy_bulk_insert` with `BulkInsertSafe`
          # once https://gitlab.com/gitlab-org/gitlab/-/issues/247718 is fixed.
          # When this is fixed, we can remove the call to
          # `with_project_iid_supply` above, since the objects will be instantiated
          # and callbacks (including `ensure_project_iid!`) will fire.
          ::ApplicationRecord.legacy_bulk_insert( # rubocop:disable Gitlab/BulkInsert
            DesignManagement::Design.table_name,
            new_rows,
            return_ids: true
          )
        end
      end

      def copy_versions!
        version_attributes = attributes_config[:version_attributes]
        # `shas` are the list of Git commits made during the Git copy phase,
        # and will be ordered 1:1 with old versions
        shas_enum = shas.to_enum

        new_rows = versions.map do |version|
          version.attributes.slice(*version_attributes).merge(
            issue_id: target_issue.id,
            sha: sha_attribute.serialize(shas_enum.next)
          )
        end

        # TODO Replace `ApplicationRecord.legacy_bulk_insert` with `BulkInsertSafe`
        # once https://gitlab.com/gitlab-org/gitlab/-/issues/247718 is fixed.
        ::ApplicationRecord.legacy_bulk_insert( # rubocop:disable Gitlab/BulkInsert
          DesignManagement::Version.table_name,
          new_rows,
          return_ids: true
        )
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def copy_actions!(new_design_ids, new_version_ids)
        # Create a map of <Old design id> => <New design id>
        design_id_map = new_design_ids.each_with_index.to_h do |design_id, i|
          [designs[i].id, design_id]
        end

        # Create a map of <Old version id> => <New version id>
        version_id_map = new_version_ids.each_with_index.to_h do |version_id, i|
          [versions[i].id, version_id]
        end

        actions = DesignManagement::Action.unscoped.select(:design_id, :version_id, :event).where(design: designs, version: versions)

        new_rows = actions.map do |action|
          {
            design_id: design_id_map[action.design_id],
            version_id: version_id_map[action.version_id],
            event: action.event_before_type_cast
          }
        end

        # We cannot use `BulkInsertSafe` because of the uploader mounted in `Action`.
        ::ApplicationRecord.legacy_bulk_insert( # rubocop:disable Gitlab/BulkInsert
          DesignManagement::Action.table_name,
          new_rows
        )
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def commit_message(version)
        "Copy commit #{version.sha} from issue #{issue.to_reference(full: true)}"
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def copy_notes!(design_ids)
        new_designs = DesignManagement::Design.unscoped.find(design_ids)

        # Execute another query to filter only designs with notes
        DesignManagement::Design.unscoped.where(id: designs).joins(:notes).distinct.find_each(batch_size: 100) do |old_design|
          new_design = new_designs.find { |d| d.filename == old_design.filename }

          Notes::CopyService.new(current_user, old_design, new_design).execute
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def link_lfs_files!
        oids = blobs.values.flat_map(&:values).map(&:lfs_oid)
        repository_type = LfsObjectsProject.repository_types[:design]

        lfs_objects = oids.each_slice(1000).flat_map do |oids_batch|
          LfsObject.for_oids(oids_batch).not_linked_to_project(target_project, repository_type: repository_type)
        end

        new_rows = lfs_objects.compact.map do |lfs_object|
          {
            project_id: target_project.id,
            lfs_object_id: lfs_object.id,
            repository_type: repository_type
          }
        end

        # We cannot use `BulkInsertSafe` due to the LfsObjectsProject#update_project_statistics
        # callback that fires after_commit.
        ::ApplicationRecord.legacy_bulk_insert( # rubocop:disable Gitlab/BulkInsert
          LfsObjectsProject.table_name,
          new_rows,
          on_conflict: :do_nothing # Upsert
        )
      end

      # Blob data is used to find the oids for LfsObjects and to copy to Git.
      # Blobs are reasonably small in memory, as their data are LFS Pointer files.
      #
      # Returns all blobs for the designs as a Hash of `{ Blob#commit_id => { Design#filename => Blob } }`
      def blobs
        @blobs ||= begin
          items = versions.flat_map { |v| v.designs.map { |d| [v.sha, DesignManagement::Design.build_full_path(issue, d)] } }

          repository.blobs_at(items).each_with_object({}) do |blob, h|
            design = designs.find { |d| DesignManagement::Design.build_full_path(issue, d) == blob.path }

            h[blob.commit_id] ||= {}
            h[blob.commit_id][design.filename] = blob
          end
        end
      end

      def attributes_config
        @attributes_config ||= YAML.load_file(attributes_config_file).symbolize_keys
      end

      def attributes_config_file
        Rails.root.join('lib/gitlab/design_management/copy_design_collection_model_attributes.yml')
      end
    end
  end
end
