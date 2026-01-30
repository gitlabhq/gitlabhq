# frozen_string_literal: true

# Disable Sorbet's runtime checks because:
# - GitLab does not use Sorbet yet
#   - See https://docs.gitlab.com/development/backend/ruby_style_guide/#type-safety
# - We ignore these checks in 3rd party libraries

T::Configuration.default_checked_level = :never
