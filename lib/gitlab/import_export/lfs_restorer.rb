# frozen_string_literal: true

module Gitlab
  module ImportExport
    class LfsRestorer
      include Gitlab::Utils::StrongMemoize

      attr_accessor :project, :shared

      def initialize(project:, shared:)
        @project = project
        @shared = shared
      end

      def restore
        return true if lfs_file_paths.empty?

        lfs_file_paths.each do |file_path|
          link_or_create_lfs_object!(file_path)
        end

        true
      rescue StandardError => e
        shared.error(e)
        false
      end

      private

      def link_or_create_lfs_object!(path)
        size = File.size(path)
        oid = LfsObject.calculate_oid(path)

        lfs_object = LfsObject.find_or_initialize_by(oid: oid, size: size)
        lfs_object.file = File.open(path) unless lfs_object.file&.exists?
        lfs_object.save! if lfs_object.changed?

        repository_types(oid).each do |repository_type|
          LfsObjectsProject.create!(
            project: project,
            lfs_object: lfs_object,
            repository_type: repository_type
          )
        end
      end

      def repository_types(oid)
        # We allow support for imports created before the `lfs-objects.json`
        # file was generated. In this case, the restorer will link an LFS object
        # with a single `lfs_objects_projects` relation.
        #
        # This allows us backwards-compatibility without version bumping.
        # See https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/30830#note_192608870
        return ['project'] unless has_lfs_json?

        lfs_json[oid]
      end

      def lfs_file_paths
        @lfs_file_paths ||= Dir.glob("#{lfs_storage_path}/*")
      end

      def has_lfs_json?
        strong_memoize(:has_lfs_json) do
          File.exist?(lfs_json_path)
        end
      end

      def lfs_json
        return {} unless has_lfs_json?

        @lfs_json ||=
          begin
            json = IO.read(lfs_json_path)
            Gitlab::Json.parse(json)
          rescue StandardError
            raise Gitlab::ImportExport::Error, 'Incorrect JSON format'
          end
      end

      def lfs_storage_path
        File.join(shared.export_path, ImportExport.lfs_objects_storage)
      end

      def lfs_json_path
        File.join(shared.export_path, ImportExport.lfs_objects_filename)
      end
    end
  end
end
