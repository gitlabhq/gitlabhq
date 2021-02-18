# frozen_string_literal: true

namespace :gitlab do
  namespace :external_diffs do
    desc "Override external diffs in file storage to be in object storage instead. This does not change the actual location of the data"
    task force_object_storage: :environment do |t, args|
      ansi = Gitlab::Utils.to_boolean(ENV.fetch('ANSI', true))
      batch = ENV.fetch('BATCH_SIZE', 1000)
      start_id = ENV.fetch('START_ID', nil)
      end_id = ENV.fetch('END_ID', nil)
      update_delay = args.fetch('UPDATE_DELAY', 1)

      # Use ANSI codes to overwrite the same line repeatedly if supported
      newline = ansi ? "\x1B8\x1B[2K" : "\n"

      total = 0

      # The only useful index on the table is by id, so scan through the whole
      # table by that and filter out those we don't want on each relation
      MergeRequestDiff.in_batches(of: batch, start: start_id, finish: end_id) do |relation| # rubocop:disable Cop/InBatches
        count = relation
          .except(:order)
          .where(stored_externally: true, external_diff_store: ExternalDiffUploader::Store::LOCAL)
          .update_all(external_diff_store: ExternalDiffUploader::Store::REMOTE)

        total += count

        if count > 0
          print "#{newline}#{total} updated..."
          sleep(update_delay) if update_delay > 0
        end
      end

      puts "done!"
    end
  end
end
