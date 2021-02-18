# frozen_string_literal: true

namespace :file_hooks do
  desc 'Validate existing file hooks'
  task validate: :environment do
    puts 'Validating file hooks from /file_hooks and /plugins directories'

    Gitlab::FileHook.files.each do |file|
      if File.dirname(file).ends_with?('plugins')
        puts 'DEPRECATED: /plugins directory is deprecated and will be removed in 14.0. ' \
          'Please move your files into /file_hooks directory.'
      end

      success, message = Gitlab::FileHook.execute(file, Gitlab::DataBuilder::Push::SAMPLE_DATA)

      if success
        puts "* #{file} succeed (zero exit code)."
      else
        puts "* #{file} failure (non-zero exit code). #{message}"
      end
    end
  end
end
