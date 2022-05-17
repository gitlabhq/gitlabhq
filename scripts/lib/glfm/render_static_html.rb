# frozen_string_literal: true

require_relative 'constants'
require_relative 'shared'

# Purpose:
# - Reads a set of markdown examples from a hash which has been serialized to disk
# - Converts each example to static HTML using the `markdown` helper
# - Writes the HTML for each example to a hash which is serialized to disk
#
# It should be invoked via `rails runner` from the Rails root directory.
# It is intended to be invoked from the `update_example_snapshots.rb` script class.
module Glfm
  class RenderStaticHtml
    include Constants
    include Shared

    def process
      markdown_yml_path = ARGV[0]
      markdown_hash = YAML.load_file(markdown_yml_path)

      # NOTE: We COULD parallelize this loop like the Javascript WYSIWYG example generation does,
      # but it wouldn't save much time. Most of the time is spent loading the Rails environment
      # via `rails runner`. In initial testing, this loop only took ~7 seconds while the entire
      # script took ~20 seconds. Unfortunately, there's no easy way to execute
      # `ApplicationController.helpers.markdown` without using `rails runner`
      static_html_hash = markdown_hash.transform_values do |markdown|
        ApplicationController.helpers.markdown(markdown)
      end

      static_html_tempfile_path = Dir::Tmpname.create(STATIC_HTML_TEMPFILE_BASENAME) do |path|
        tmpfile = File.open(path, 'w')
        YAML.dump(static_html_hash, tmpfile)
        tmpfile.close
      end

      # Write the path to the output file to stdout
      print static_html_tempfile_path
    end
  end
end

# current_user must be in global scope for `markdown` helper to work. Currently it's not supported
# to pass it in the context.
def current_user
  # TODO: This will likely need to be a more realistic user object for some of the GLFM examples
  User.new
end

Glfm::RenderStaticHtml.new.process
