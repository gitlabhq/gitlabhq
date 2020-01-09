# frozen_string_literal: true

return if Rails.env.production?

module Gitlab
  module Graphql
    module Docs
      # Gitlab renderer for graphql-docs.
      # Uses HAML templates to parse markdown and generate .md files.
      # It uses graphql-docs helpers and schema parser, more information in https://github.com/gjtorikian/graphql-docs.
      #
      # Arguments:
      #   schema - the GraphQL schema definition. For GitLab should be: GitlabSchema.graphql_definition
      #   output_dir: The folder where the markdown files will be saved
      #   template: The path of the haml template to be parsed
      class Renderer
        include Gitlab::Graphql::Docs::Helper

        def initialize(schema, output_dir:, template:)
          @output_dir = output_dir
          @template = template
          @layout = Haml::Engine.new(File.read(template))
          @parsed_schema = GraphQLDocs::Parser.new(schema, {}).parse
        end

        def contents
          # Render and remove an extra trailing new line
          @contents ||= @layout.render(self).sub!(/\n(?=\Z)/, '')
        end

        def write
          filename = File.join(@output_dir, 'index.md')

          FileUtils.mkdir_p(@output_dir)
          File.write(filename, contents)
        end
      end
    end
  end
end
