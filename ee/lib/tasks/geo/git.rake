namespace :geo do
  namespace :git do
    namespace :housekeeping do
      using ProgressBar::Refinements::Enumerator

      desc "GitLab | Git | Housekeeping | Garbage Collection"
      task gc: :gitlab_environment do
        flag_for_housekeeping(Gitlab::CurrentSettings.housekeeping_gc_period)
      end

      desc "GitLab | Git | Housekeeping | Full Repack"
      task full_repack: :gitlab_environment do
        flag_for_housekeeping(Gitlab::CurrentSettings.housekeeping_full_repack_period)
      end

      desc "GitLab | Git | Housekeeping | Incremental Repack"
      task incremental_repack: :gitlab_environment do
        flag_for_housekeeping(Gitlab::CurrentSettings.housekeeping_incremental_repack_period)
      end

      def flag_for_housekeeping(period)
        Geo::ProjectRegistry.select(:id, :project_id).find_in_batches.with_progressbar(format: '%t: |%B| %p%% %e') do |batches|
          batches.each do |registry|
            registry.set_syncs_since_gc!(period - 1)
          end
        end
      end
    end
  end
end
