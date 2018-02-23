namespace :plugins do
  desc 'Validate existing plugins'
  task validate: :environment do
    puts 'Validating plugins from /plugins directory'

    Gitlab::Plugin.files.each do |file|
      result = Gitlab::Plugin.execute(file, Gitlab::DataBuilder::Push::SAMPLE_DATA)

      if result
        puts "* #{file} succeed (zero exit code)"
      else
        puts "* #{file} failure (non-zero exit code)"
      end
    end
  end
end
