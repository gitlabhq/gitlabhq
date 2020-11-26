# frozen_string_literal: true

module Projects
  # Tries to schedule a move for every project with repositories on the source shard
  class ScheduleBulkRepositoryShardMovesService
    include BaseServiceUtility

    def execute(source_storage_name, destination_storage_name = nil)
      shard = Shard.find_by_name!(source_storage_name)

      ProjectRepository.for_shard(shard).each_batch(column: :project_id) do |relation|
        Project.id_in(relation.select(:project_id)).each do |project|
          project.with_lock do
            next if project.repository_storage != source_storage_name

            storage_move = project.repository_storage_moves.build(
              source_storage_name: source_storage_name,
              destination_storage_name: destination_storage_name
            )

            unless storage_move.schedule
              log_info("Project #{project.full_path} (#{project.id}) was skipped: #{storage_move.errors.full_messages.to_sentence}")
            end
          end
        end
      end

      success
    end

    def self.enqueue(source_storage_name, destination_storage_name = nil)
      ::ProjectScheduleBulkRepositoryShardMovesWorker.perform_async(source_storage_name, destination_storage_name)
    end
  end
end
