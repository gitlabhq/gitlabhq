namespace :gitlab do
  namespace :uploads do
    desc 'GitLab | Uploads | Check integrity of uploaded files'
    task check: :environment do
      puts 'Checking integrity of uploaded files'

      uploads_batches do |batch|
        batch.each do |upload|
          puts "- Checking file (#{upload.id}): #{upload.absolute_path}".color(:green)

          if upload.exist?
            check_checksum(upload)
          else
            puts "  * File does not exist on the file system".color(:red)
          end
        end
      end

      puts 'Done!'
    end

    desc 'GitLab | Uploads | Migrate the uploaded files to object storage'
    task :migrate, [:uploader_class, :model_class, :mounted_as] => :environment do |task, args|
      MIGRATE_TO_STORE = ObjectStorage::Store::REMOTE

      class MigrationResult
        attr_reader :upload
        attr_accessor :error

        def initialize(upload, error = nil)
          @upload, @error = upload, error
        end

        def success?
          error.nil?
        end

        def to_s
          success? ? "Migration sucessful." : "Error while migrating #{upload.id}: #{error.message}"
        end
      end

      uploader_class = args.uploader_class.constantize
      model_class = args.model_class.constantize
      mounted_as = args.mounted_as&.gsub(':', '')&.to_sym

      global_results = []
      Upload.preload(:model)
        .where.not(store: MIGRATE_TO_STORE)
        .where(uploader: uploader_class.to_s,
               model_type: model_class.to_s)
        .in_batches(of: batch_size) do |batch|

        results = migrate(build_uploaders(batch, mounted_as))
        report(results)

        global_results.concat(results)
      end

      puts "\n === Migration summary ==="
      report(global_results)
    end

    def report(results)
      results = results.group_by(&:success?)
      success, errors = [
        results.fetch(true, []),
        results.fetch(false, [])
      ]
      batch_color = errors.count == 0 ? :green : :red

      puts "Migrated #{success.count}/#{success.count + errors.count} files.".color(batch_color)
      errors.each { |e| puts("\t#{e}").color(:red) }
    end

    def build_uploaders(uploads, mounted_as)
      uploads.map { |upload| upload.build_uploader(mounted_as) }
    end

    def migrate(uploaders)
      uploaders.map do |uploader|
        result = MigrationResult.new(uploader.upload)
        begin
          uploader.migrate!(MIGRATE_TO_STORE)
          result
        rescue CarrierWave::UploadError => e
          result.error = e
          result
        end
      end
    end

    def batch_size
      ENV.fetch('BATCH', 200).to_i
    end

    def calculate_checksum(absolute_path)
      Digest::SHA256.file(absolute_path).hexdigest
    end

    def check_checksum(upload)
      checksum = calculate_checksum(upload.absolute_path)

      if checksum != upload.checksum
        puts "  * File checksum (#{checksum}) does not match the one in the database (#{upload.checksum})".color(:red)
      end
    end

    def uploads_batches(&block)
      Upload.all.in_batches(of: batch_size, start: ENV['ID_FROM'], finish: ENV['ID_TO']) do |relation| # rubocop: disable Cop/InBatches
        yield relation
      end
    end
  end
end
