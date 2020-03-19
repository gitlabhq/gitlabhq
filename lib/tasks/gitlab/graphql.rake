# frozen_string_literal: true

return if Rails.env.production?

require 'graphql/rake_task'

namespace :gitlab do
  OUTPUT_DIR = Rails.root.join("doc/api/graphql/reference")
  TEMPLATES_DIR = 'lib/gitlab/graphql/docs/templates/'

  # Make all feature flags enabled so that all feature flag
  # controlled fields are considered visible and are output.
  # Also avoids pipeline failures in case developer
  # dumps schema with flags disabled locally before pushing
  task enable_feature_flags: :environment do
    class Feature
      def self.enabled?(*args)
        true
      end
    end
  end

  # Defines tasks for dumping the GraphQL schema:
  # - gitlab:graphql:schema:dump
  # - gitlab:graphql:schema:idl
  # - gitlab:graphql:schema:json
  GraphQL::RakeTask.new(
    schema_name: 'GitlabSchema',
    dependencies: [:environment, :enable_feature_flags],
    directory: OUTPUT_DIR,
    idl_outfile: "gitlab_schema.graphql",
    json_outfile: "gitlab_schema.json"
  )

  namespace :graphql do
    desc 'GitLab | GraphQL | Generate GraphQL docs'
    task compile_docs: [:environment, :enable_feature_flags] do
      renderer = Gitlab::Graphql::Docs::Renderer.new(GitlabSchema.graphql_definition, render_options)

      renderer.write

      puts "Documentation compiled."
    end

    desc 'GitLab | GraphQL | Check if GraphQL docs are up to date'
    task check_docs: [:environment, :enable_feature_flags] do
      renderer = Gitlab::Graphql::Docs::Renderer.new(GitlabSchema.graphql_definition, render_options)

      doc = File.read(Rails.root.join(OUTPUT_DIR, 'index.md'))

      if doc == renderer.contents
        puts "GraphQL documentation is up to date"
      else
        format_output('GraphQL documentation is outdated! Please update it by running `bundle exec rake gitlab:graphql:compile_docs`.')
        abort
      end
    end

    desc 'GitLab | GraphQL | Check if GraphQL schemas are up to date'
    task check_schema: [:environment, :enable_feature_flags] do
      idl_doc = File.read(Rails.root.join(OUTPUT_DIR, 'gitlab_schema.graphql'))
      json_doc = File.read(Rails.root.join(OUTPUT_DIR, 'gitlab_schema.json'))

      if idl_doc == GitlabSchema.to_definition && json_doc == GitlabSchema.to_json
        puts "GraphQL schema is up to date"
      else
        format_output('GraphQL schema is outdated! Please update it by running `bundle exec rake gitlab:graphql:schema:dump`.')
        abort
      end
    end
  end
end

def render_options
  {
    output_dir: OUTPUT_DIR,
    template: Rails.root.join(TEMPLATES_DIR, 'default.md.haml')
  }
end

def format_output(str)
  heading = '#' * 10
  puts heading
  puts '#'
  puts "# #{str}"
  puts '#'
  puts heading
end
