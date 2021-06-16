# frozen_string_literal: true

namespace :file_hooks do
  desc 'Validate existing file hooks'
  task validate: :environment do
    puts 'Validating file hooks from /file_hooks directories'

    Gitlab::FileHook.files.each do |file|
      success, message = Gitlab::FileHook.execute(file, Gitlab::DataBuilder::Push::SAMPLE_DATA)

      if success
        puts "* #{file} succeed (zero exit code)."
      else
        puts "* #{file} failure (non-zero exit code). #{message}"
      end
    end
  end
end
