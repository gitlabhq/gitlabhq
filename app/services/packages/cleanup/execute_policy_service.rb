# frozen_string_literal: true

module Packages
  module Cleanup
    class ExecutePolicyService
      include Gitlab::Utils::StrongMemoize

      MAX_EXECUTION_TIME = 250.seconds

      DUPLICATED_FILES_BATCH_SIZE = 10_000
      MARK_PACKAGE_FILES_FOR_DESTRUCTION_SERVICE_BATCH_SIZE = 200

      delegate :project, to: :@policy, private: true

      def initialize(policy)
        @policy = policy
        @counts = {
          marked_package_files_total_count: 0,
          unique_package_id_and_file_name_total_count: 0
        }
      end

      def execute
        cleanup_duplicated_files
      end

      private

      def cleanup_duplicated_files
        return if @policy.keep_n_duplicated_package_files_disabled?

        result = installable_package_files.each_batch(of: DUPLICATED_FILES_BATCH_SIZE) do |package_files|
          break :timeout if cleanup_duplicated_files_on(package_files) == :timeout
        end

        response_success(timeout: result == :timeout)
      end

      def installable_package_files
        ::Packages::PackageFile
          .installable
          .for_package_ids(project.packages.installable)
      end

      def cleanup_duplicated_files_on(package_files)
        unique_package_id_and_file_name_from(package_files).each do |package_id, file_name|
          result = remove_duplicated_files_for(package_id: package_id, file_name: file_name)
          @counts[:marked_package_files_total_count] += result.payload[:marked_package_files_count]
          @counts[:unique_package_id_and_file_name_total_count] += 1

          break :timeout unless result.success?
        end
      end

      def unique_package_id_and_file_name_from(package_files)
        # rubocop: disable CodeReuse/ActiveRecord -- This is a highly custom query for this service, that's why it's not in the model.
        package_files.group(:package_id, :file_name)
          .having("COUNT(*) > #{@policy.keep_n_duplicated_package_files}")
          .pluck(:package_id, :file_name) # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- package_files is already in batches
        # rubocop: enable CodeReuse/ActiveRecord
      end

      def remove_duplicated_files_for(package_id:, file_name:)
        base = ::Packages::PackageFile.for_package_ids(package_id)
                 .installable
                 .with_file_name(file_name)
        ids_to_keep = base.recent
                        .limit(@policy.keep_n_duplicated_package_files)
                        .pluck_primary_key

        keep_conan_manifest_file(base, ids_to_keep) if file_name == ::Packages::Conan::FileMetadatum::CONAN_MANIFEST

        duplicated_package_files = base.id_not_in(ids_to_keep)
        ::Packages::MarkPackageFilesForDestructionService.new(duplicated_package_files)
          .execute(batch_deadline: batch_deadline, batch_size: MARK_PACKAGE_FILES_FOR_DESTRUCTION_SERVICE_BATCH_SIZE)
      end

      def keep_conan_manifest_file(base, ids)
        recipe_manifest_id = base.with_conan_file_type(:recipe_file).recent.limit(1).pluck_primary_key
        ids.concat(recipe_manifest_id)
      end

      def batch_deadline
        MAX_EXECUTION_TIME.from_now
      end
      strong_memoize_attr :batch_deadline

      def response_success(timeout:)
        ServiceResponse.success(
          message: "Packages cleanup policy executed for project #{project.id}",
          payload: {
            timeout: timeout,
            counts: @counts
          }
        )
      end
    end
  end
end
