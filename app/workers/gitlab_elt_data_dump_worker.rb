class GitlabEltDataDumpWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    return unless Gitlab::CurrentSettings.elt_database_dump_enabled

    options = Pseudonymity::Options.new(
      config: YAML.load_file(Rails.root.join(Gitlab.config.pseudonymizer.manifest)),
      start_at: Time.now.utc
    )

    table = Pseudonymity::Table.new(options)
    table.tables_to_csv

    upload = Pseudonymity::UploadService.new(options)
    upload.upload
    upload.cleanup
  end
end
