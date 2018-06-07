class PseudonymizerWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    return unless Gitlab::CurrentSettings.pseudonymizer_enabled?

    options = Pseudonymizer::Options.new(
      config: YAML.load_file(Rails.root.join(Gitlab.config.pseudonymizer.manifest)),
      start_at: Time.now.utc
    )

    dumper = Pseudonymizer::Dumper.new(options)
    dumper.tables_to_csv

    uploader = Pseudonymizer::Uploader.new(options)
    uploader.upload
    uploader.cleanup
  end
end
