namespace :gitlab do
  namespace :db do
    desc 'Output pseudonymity dump of selected tables'
    task pseudonymizer: :environment do
      abort "The pseudonymizer is not available with this license." unless License.feature_available?(:pseudonymizer)
      abort "The pseudonymizer is disabled." unless Gitlab::CurrentSettings.pseudonymizer_enabled?

      options = Pseudonymizer::Options.new(
        config: YAML.load_file(Gitlab.config.pseudonymizer.manifest),
        output_dir: ENV['PSEUDONYMIZER_OUTPUT_DIR']
      )

      dumper = Pseudonymizer::Dumper.new(options)
      uploader = Pseudonymizer::Uploader.new(options)

      unless uploader.available?
        abort "There is an error in the pseudonymizer object store configuration."
      end

      begin
        dumper.tables_to_csv
        uploader.upload
      ensure
        uploader.cleanup
      end
    end
  end
end
