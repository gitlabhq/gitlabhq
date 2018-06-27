class ImportExportCleanUpService
  LAST_MODIFIED_TIME_IN_MINUTES = 1440

  attr_reader :mmin, :path

  def initialize(mmin = LAST_MODIFIED_TIME_IN_MINUTES)
    @mmin = mmin
    @path = Gitlab::ImportExport.storage_path
  end

  def execute
    Gitlab::Metrics.measure(:import_export_clean_up) do
      next unless File.directory?(path)

      clean_up_export_files
    end
  end

  private

  def clean_up_export_files
    Gitlab::Popen.popen(%W(find #{path} -not -path #{path} -mmin +#{mmin} -delete))
  end
end
