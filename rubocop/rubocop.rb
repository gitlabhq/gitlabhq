# rubocop:disable Naming/FileName
# frozen_string_literal: true

# Auto-require all cops under `rubocop/cop/**/*.rb`
Dir[File.join(__dir__, 'cop', '**', '*.rb')].sort.each { |file| require file }

# rubocop:enable Naming/FileName
