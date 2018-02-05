namespace :gitlab do
  namespace :uploads do
    desc 'GitLab | Uploads | Migrate the uploaded files to object storage'
    task :migrate, [:uploader_class, :model_class, :mounted_as] => :environment do |task, args|
      batch_size     = ENV.fetch('BATCH', 200).to_i
      @to_store      = ObjectStorage::Store::REMOTE
      @mounted_as    = args.mounted_as&.gsub(':', '')&.to_sym
      uploader_class = args.uploader_class.constantize
      model_class    = args.model_class.constantize

      Upload
        .where.not(store: @to_store)
        .where(uploader: uploader_class.to_s,
               model_type: model_class.base_class.sti_name)
        .in_batches(of: batch_size, &method(:enqueue_batch)) # rubocop: disable Cop/InBatches
    end

    def enqueue_batch(batch)
      job = ObjectStorage::MigrateUploadsWorker.enqueue!(batch,
                                                         @mounted_as,
                                                         @to_store)
      puts "Enqueued job: #{job}"
    rescue ObjectStorage::MigrateUploadsWorker::SanityCheckError => e
      # continue for the next batch
      puts "Could not enqueue batch (#{batch.ids}) #{e.message}".color(:red)
    end
  end
end
