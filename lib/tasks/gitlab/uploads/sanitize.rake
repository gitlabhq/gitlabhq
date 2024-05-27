# frozen_string_literal: true

namespace :gitlab do
  namespace :uploads do
    namespace :sanitize do
      desc 'GitLab | Uploads | Remove EXIF from images.'
      task :remove_exif, [:start_id, :stop_id, :dry_run, :sleep_time, :uploader, :since] => :environment do |task, args|
        args.with_defaults(dry_run: 'true')
        args.with_defaults(sleep_time: 0.3)

        logger = Logger.new($stdout)

        sanitizer = Gitlab::Sanitizers::Exif.new(logger: logger)
        sanitizer.batch_clean(start_id: args.start_id, stop_id: args.stop_id,
          dry_run: args.dry_run != 'false',
          sleep_time: args.sleep_time.to_f,
          uploader: args.uploader,
          since: args.since)
      end
    end
  end
end
