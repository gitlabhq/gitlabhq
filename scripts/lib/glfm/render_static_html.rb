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

      context = build_context

      # NOTE: We COULD parallelize this loop like the Javascript WYSIWYG example generation does,
      # but it wouldn't save much time. Most of the time is spent loading the Rails environment
      # via `rails runner`. In initial testing, this loop only took ~7 seconds while the entire
      # script took ~20 seconds. Unfortunately, there's no easy way to execute
      # `Banzai.render_and_post_process` without using `rails runner`
      static_html_hash = markdown_hash.transform_values do |markdown|
        Banzai.render_and_post_process(markdown, context)
      end

      static_html_tempfile_path = Dir::Tmpname.create(STATIC_HTML_TEMPFILE_BASENAME) do |path|
        tmpfile = File.open(path, 'w')
        YAML.dump(static_html_hash, tmpfile)
        tmpfile.close
      end

      # Write the path to the output file to stdout
      print static_html_tempfile_path
    end

    private

    def build_context
      user_username = 'glfm_user_username'
      user = User.find_by_username(user_username) ||
        User.create!(
          email: "glfm_user_email@example.com",
          name: "glfm_user_name",
          password: "glfm_user_password",
          username: user_username
        )

      # Ensure that we never try to hit Gitaly, even if we
      # reload the project
      Project.define_method(:skip_disk_validation) do
        true
      end

      project_name = 'glfm_project_name'
      project = Project.find_by_name(project_name) ||
        Project.create!(
          creator: user,
          description: "glfm_project_description",
          name: project_name,
          namespace: user.namespace,
          path: 'glfm_project_path'
        )

      {
        only_path: false,
        current_user: user,
        project: project
      }
    end
  end
end

Glfm::RenderStaticHtml.new.process
