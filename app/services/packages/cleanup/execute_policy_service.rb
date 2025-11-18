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
        ::Packages::PackageFile.installable.for_projects(project)
      end

      def cleanup_duplicated_files_on(package_files)
        unique_package_id_and_file_name_and_package_type_from(package_files)
          .each do |package_id, file_name, package_type|
          result = remove_duplicated_files_for(package_id: package_id, file_name: file_name, package_type: package_type)
          @counts[:marked_package_files_total_count] += result.payload[:marked_package_files_count]
          @counts[:unique_package_id_and_file_name_total_count] += 1

          break :timeout unless result.success?
        end
      end

      def unique_package_id_and_file_name_and_package_type_from(package_files)
        # rubocop: disable CodeReuse/ActiveRecord -- This is a highly custom query for this service, that's why it's not in the model.
        package_files.joins(:package)
                     .group(:package_id, :file_name, "#{::Packages::Package.table_name}.package_type")
                     .having("COUNT(*) > #{@policy.keep_n_duplicated_package_files}")
                     .pluck(:package_id, :file_name, "#{::Packages::Package.table_name}.package_type") # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- package_files is already in batches
        # rubocop: enable CodeReuse/ActiveRecord
      end

      def remove_duplicated_files_for(package_id:, file_name:, package_type:)
        base = ::Packages::PackageFile.for_package_ids(package_id)
                 .installable
                 .with_file_name(file_name)

        ids_to_keep = if package_type == 'conan'
                        conan_keep_n_duplicate_ids(base)
                      else
                        base.recent
                          .limit(@policy.keep_n_duplicated_package_files)
                          .pluck_primary_key
                      end

        duplicated_package_files = base.id_not_in(ids_to_keep)
        ::Packages::MarkPackageFilesForDestructionService.new(duplicated_package_files)
          .execute(batch_deadline: batch_deadline, batch_size: MARK_PACKAGE_FILES_FOR_DESTRUCTION_SERVICE_BATCH_SIZE)
      end

      def conan_keep_n_duplicate_ids(package_files)
        # rubocop: disable CodeReuse/ActiveRecord -- This is a highly custom query for this service, that's why it's not in the model.
        metadatum = ::Packages::Conan::FileMetadatum.arel_table
        partition = Arel::Nodes::Window.new
                                       .partition(
                                         metadatum[:conan_file_type], metadatum[:recipe_revision_id],
                                         metadatum[:package_revision_id], metadatum[:package_reference_id]
                                       )
        row_number = Arel::Nodes::NamedFunction.new('ROW_NUMBER', [])
                                               .over(
                                                 partition.order(
                                                   ::Packages::PackageFile.arel_table[:created_at].desc
                                                 )
                                               )
                                               .as('rn')

        inner_query = package_files.joins(:conan_file_metadatum).select(:id, row_number)
        cte = Gitlab::SQL::CTE.new(:ranked_files, inner_query)

        ::Packages::PackageFile.with(cte.to_arel)
                               .select(cte.table[:id])
                               .where(cte.table[:rn].lteq(@policy.keep_n_duplicated_package_files))
                               .from(cte.table)
                               .ids
        # rubocop: enable CodeReuse/ActiveRecord
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
