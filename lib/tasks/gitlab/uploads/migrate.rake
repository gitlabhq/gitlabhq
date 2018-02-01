require_relative 'helpers'

include UploadTaskHelpers

namespace :gitlab do
  namespace :uploads do
    desc 'GitLab | Uploads | Migrate the uploaded files to object storage'
    task :migrate, [:uploader_class, :model_class, :mounted_as] => :environment do |task, args|
      to_store       = ObjectStorage::Store::REMOTE
      uploader_class = args.uploader_class.constantize
      model_class    = args.model_class.constantize
      mounted_as     = args.mounted_as&.gsub(':', '')&.to_sym

      Upload
        .where.not(store: to_store)
        .where(uploader: uploader_class.to_s,
               model_type: model_class.to_s)
        .in_batches(of: batch_size) do |batch| # rubocop: disable Cop/InBatches
        job = Gitlab::BackgroundMigration::MigrateUploadsToObjectStorage.enqueue!(batch, mounted_as, to_store)
        puts "Enqueued job: #{job}"
      end
    end
  end
end
