# frozen_string_literal: true

# TODO: Remove this once we're on Ruby 3
# https://gitlab.com/gitlab-org/gitlab/-/issues/393651
unless YAML.respond_to?(:safe_load_file)
  module YAML
    # Temporary Ruby 2 back-compat workaround.
    #
    # This method only exists as of stdlib 3.0.0:
    # https://ruby-doc.org/stdlib-3.0.0/libdoc/psych/rdoc/Psych.html
    def self.safe_load_file(path, **options)
      YAML.safe_load(File.read(path), **options)
    end
  end
end
