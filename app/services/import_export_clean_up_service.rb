# frozen_string_literal: true

class ImportExportCleanUpService
  LAST_MODIFIED_TIME_IN_MINUTES = 1440

  attr_reader :mmin, :path

  def initialize(mmin = LAST_MODIFIED_TIME_IN_MINUTES)
    @mmin = mmin
    @path = Gitlab::ImportExport.storage_path
  end

  def execute
    Gitlab::Metrics.measure(:import_export_clean_up) do
      execute_cleanup
    end
  end

  private

  def execute_cleanup
    clean_up_export_object_files
  ensure
    # We don't want a failure in cleaning up object storage from
    # blocking us from cleaning up temporary storage.
    clean_up_export_files if File.directory?(path)
  end

  def clean_up_export_files
    Gitlab::Popen.popen(%W(find #{path} -not -path #{path} -mmin +#{mmin} -delete))
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def clean_up_export_object_files
    ImportExportUpload.where('updated_at < ?', mmin.minutes.ago).each do |upload|
      upload.remove_export_file!
      upload.save!
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
