# frozen_string_literal: true

# Display package version data acording to PyPI
# Simple API: https://warehouse.pypa.io/api-reference/legacy/#simple-project-api
module Packages
  module Pypi
    class SimplePresenterBase
      include API::Helpers::RelatedResourcesHelpers

      def initialize(packages, project_or_group)
        @packages = packages
        @project_or_group = project_or_group
      end

      def body
        <<-HTML.lstrip
        <!DOCTYPE html>
        <html>
          <head>
            <title>Links for #{escape(body_name)}</title>
          </head>
          <body>
            <h1>Links for #{escape(body_name)}</h1>
            #{links}
          </body>
        </html>
        HTML
      end

      private

      def package_link(url, required_python, name)
        "<a href=\"#{url}\" data-requires-python=\"#{escape(required_python)}\">#{name}</a>"
      end

      def escape(str)
        ERB::Util.html_escape(str)
      end

      def project?
        @project_or_group.is_a?(::Project)
      end

      def group?
        @project_or_group.is_a?(::Group)
      end

      def available_packages
        @packages.not_pending_destruction
      end
    end
  end
end
