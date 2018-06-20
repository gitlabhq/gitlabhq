class PseudonymizerWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    abort "The pseudonymizer is not available with this license." unless License.feature_available?(:pseudonymizer)
    return unless Gitlab::CurrentSettings.pseudonymizer_enabled?

    options = Pseudonymizer::Options.new(
      config: YAML.load_file(Gitlab.config.pseudonymizer.manifest),
      output_dir: ENV['PSEUDONYMIZER_OUTPUT_DIR']
    )

    dumper = Pseudonymizer::Dumper.new(options)
    uploader = Pseudonymizer::Uploader.new(options, progress_output: File.open(File::NULL, "w"))

    begin
      dumper.tables_to_csv
      uploader.upload
    ensure
      uploader.cleanup
    end
  end
end
