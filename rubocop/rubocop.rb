# rubocop:disable Naming/FileName
# frozen_string_literal: true

# Performance improvements to be upstreamed soon:
# See https://gitlab.com/gitlab-org/gitlab/-/issues/377469
require_relative 'ext/path_util'
require_relative 'ext/variable_force'

# Auto-require all cops under `rubocop/cop/**/*.rb`
Dir[File.join(__dir__, 'cop', '**', '*.rb')].sort.each { |file| require file }

# rubocop:enable Naming/FileName
