class GitlabELTDataDumpWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    return unless Gitlab::CurrentSettings.elt_database_dump_enabled
    
    Pseudonymity::Table.new.tables_to_csv
  end
end
