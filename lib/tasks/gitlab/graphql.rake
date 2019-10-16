# frozen_string_literal: true

return if Rails.env.production?

namespace :gitlab do
  OUTPUT_DIR = Rails.root.join("doc/api/graphql/reference")
  TEMPLATES_DIR = 'lib/gitlab/graphql/docs/templates/'

  namespace :graphql do
    desc 'GitLab | Generate GraphQL docs'
    task compile_docs: :environment do
      renderer = Gitlab::Graphql::Docs::Renderer.new(GitlabSchema.graphql_definition, render_options)

      renderer.write

      puts "Documentation compiled."
    end

    desc 'GitLab | Check if GraphQL docs are up to date'
    task check_docs: :environment do
      renderer = Gitlab::Graphql::Docs::Renderer.new(GitlabSchema.graphql_definition, render_options)

      doc = File.read(Rails.root.join(OUTPUT_DIR, 'index.md'))

      if doc == renderer.contents
        puts "GraphQL documentation is up to date"
      else
        puts '#' * 10
        puts '#'
        puts '# GraphQL documentation is outdated! Please update it by running `bundle exec rake gitlab:graphql:compile_docs`.'
        puts '#'
        puts '#' * 10
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
