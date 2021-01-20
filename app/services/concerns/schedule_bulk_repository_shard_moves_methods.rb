# frozen_string_literal: true

module ScheduleBulkRepositoryShardMovesMethods
  extend ActiveSupport::Concern
  include BaseServiceUtility

  class_methods do
    def enqueue(source_storage_name, destination_storage_name = nil)
      schedule_bulk_worker_klass.perform_async(source_storage_name, destination_storage_name)
    end

    def schedule_bulk_worker_klass
      raise NotImplementedError
    end
  end

  def execute(source_storage_name, destination_storage_name = nil)
    shard = Shard.find_by_name!(source_storage_name)

    repository_klass.for_shard(shard).each_batch(column: container_column) do |relation|
      container_klass.id_in(relation.select(container_column)).each do |container|
        container.with_lock do
          next if container.repository_storage != source_storage_name

          storage_move = container.repository_storage_moves.build(
            source_storage_name: source_storage_name,
            destination_storage_name: destination_storage_name
          )

          unless storage_move.schedule
            log_info("Container #{container.full_path} (#{container.id}) was skipped: #{storage_move.errors.full_messages.to_sentence}")
          end
        end
      end
    end

    success
  end

  private

  def repository_klass
    raise NotImplementedError
  end

  def container_klass
    raise NotImplementedError
  end

  def container_column
    raise NotImplementedError
  end
end
