namespace :plugins do
  desc 'Validate existing plugins'
  task validate: :environment do
    puts 'Validating plugins from /plugins directory'

    Gitlab::Plugin.files.each do |file|
      success, message = Gitlab::Plugin.execute(file, Gitlab::DataBuilder::Push::SAMPLE_DATA)

      if success
        puts "* #{file} succeed (zero exit code)."
      else
        puts "* #{file} failure (non-zero exit code). #{message}"
      end
    end
  end

  desc 'Validate existing plugins'
  task validate_async: :environment do
    Gitlab::Plugin.execute_all_async(Gitlab::DataBuilder::Push::SAMPLE_DATA)
  end
end
