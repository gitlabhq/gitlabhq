# frozen_string_literal: true

module Gitlab
  module ImportExport
    class LfsSaver
      include Gitlab::ImportExport::CommandLineUtil

      attr_accessor :lfs_json, :project, :shared

      BATCH_SIZE = 100

      def initialize(project:, shared:)
        @project = project
        @shared = shared
        @lfs_json = {}
      end

      def save
        project.lfs_objects.find_in_batches(batch_size: BATCH_SIZE) do |batch|
          batch.each do |lfs_object|
            save_lfs_object(lfs_object)
          end

          append_lfs_json_for_batch(batch)
        end

        write_lfs_json

        true
      rescue StandardError => e
        shared.error(e)

        false
      end

      private

      def save_lfs_object(lfs_object)
        if lfs_object.local_store?
          copy_file_for_lfs_object(lfs_object)
        else
          download_file_for_lfs_object(lfs_object)
        end
      end

      def download_file_for_lfs_object(lfs_object)
        destination = destination_path_for_object(lfs_object)
        mkdir_p(File.dirname(destination))

        File.open(destination, 'w') do |file|
          IO.copy_stream(URI.parse(lfs_object.file.url).open, file)
        end
      end

      def copy_file_for_lfs_object(lfs_object)
        copy_files(lfs_object.file.path, destination_path_for_object(lfs_object))
      end

      def append_lfs_json_for_batch(lfs_objects_batch)
        lfs_objects_projects = LfsObjectsProject
                                .select('lfs_objects.oid, array_agg(distinct lfs_objects_projects.repository_type) as repository_types')
                                .joins(:lfs_object)
                                .where(project: project, lfs_object: lfs_objects_batch)
                                .group('lfs_objects.oid')

        lfs_objects_projects.each do |group|
          oid = group.oid

          lfs_json[oid] ||= []
          lfs_json[oid] += group.repository_types
        end
      end

      def write_lfs_json
        mkdir_p(shared.export_path)
        File.write(lfs_json_path, lfs_json.to_json)
      end

      def destination_path_for_object(lfs_object)
        File.join(lfs_export_path, lfs_object.oid)
      end

      def lfs_export_path
        File.join(shared.export_path, ImportExport.lfs_objects_storage)
      end

      def lfs_json_path
        File.join(shared.export_path, ImportExport.lfs_objects_filename)
      end
    end
  end
end
