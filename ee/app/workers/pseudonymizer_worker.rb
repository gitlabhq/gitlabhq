class PseudonymizerWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    unless License.feature_available?(:pseudonymizer)
      Rails.logger.warn("The pseudonymizer is not available with this license.")
      return
    end

    unless unless Gitlab::CurrentSettings.pseudonymizer_enabled?
      Rails.logger.info("The pseudonymizer is disabled.")
      return
    end

    options = Pseudonymizer::Options.new(
      config: YAML.load_file(Gitlab.config.pseudonymizer.manifest),
      output_dir: ENV['PSEUDONYMIZER_OUTPUT_DIR']
    )

    dumper = Pseudonymizer::Dumper.new(options)
    uploader = Pseudonymizer::Uploader.new(options, progress_output: File.open(File::NULL, "w"))

    unless uploader.available?
      Rails.logger.error("The pseudonymizer object storage must be configured.")
      return
    end

    begin
      dumper.tables_to_csv
      uploader.upload
    ensure
      uploader.cleanup
    end
  end
end
