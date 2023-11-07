# rubocop:disable Naming/FileName
# frozen_string_literal: true

# Load ActiveSupport to ensure that core extensions like `Enumerable#exclude?`
# are available in cop rules like `Performance/CollectionLiteralInLoop`.
require 'active_support/all'

# Auto-require all cops under `rubocop/cop/**/*.rb`
Dir[File.join(__dir__, 'cop', '**', '*.rb')].each { |file| require file }

# rubocop:enable Naming/FileName
