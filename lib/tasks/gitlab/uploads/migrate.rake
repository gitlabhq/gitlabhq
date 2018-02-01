require_relative 'helpers'

namespace :gitlab do
  namespace :uploads do
    desc 'GitLab | Uploads | Migrate the uploaded files to object storage'
    task :migrate, [:uploader_class, :model_class, :mounted_as] => :environment do |task, args|
      include UploadTaskHelpers

      @to_store      = ObjectStorage::Store::REMOTE
      @mounted_as    = args.mounted_as&.gsub(':', '')&.to_sym
      uploader_class = args.uploader_class.constantize
      model_class    = args.model_class.constantize

      Upload
        .where.not(store: @to_store)
        .where(uploader: uploader_class.to_s,
               model_type: model_class.to_s)
        .in_batches(of: batch_size, &method(:process)) # rubocop: disable Cop/InBatches
    end

    def process(batch)
      job = Gitlab::BackgroundMigration::MigrateUploadsToObjectStorage.enqueue!(batch,
                                                                                @mounted_as,
                                                                                @to_store)
      puts "Enqueued job: #{job}"
    rescue Gitlab::BackgroundMigration::MigrateUploadsToObjectStorage::SanityCheckError => e
      # continue for the next batch
      puts "Could not enqueue batch (#{batch.ids}) #{e.message}".color(:red)
    end
  end
end
