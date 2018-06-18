class PseudonymizerWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    return unless Gitlab::CurrentSettings.pseudonymizer_enabled?

    options = Pseudonymizer::Options.new(
      config: YAML.load_file(Rails.root.join(Gitlab.config.pseudonymizer.manifest)),
      output_dir: ENV['PSEUDONYMIZER_OUTPUT_DIR']
    )

    dumper = Pseudonymizer::Dumper.new(options)
    dumper.tables_to_csv

    uploader = Pseudonymizer::Uploader.new(options, progress_output: File.open(File::NULL, "w"))
    uploader.upload
    uploader.cleanup
  end
end
