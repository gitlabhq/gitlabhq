# frozen_string_literal: true

return if Rails.env.production?

namespace :gitlab do
  OUTPUT_DIR = Rails.root.join("doc/api/graphql/reference")
  TEMPLATES_DIR = 'lib/gitlab/graphql/docs/templates/'

  namespace :graphql do
    desc 'GitLab | Generate GraphQL docs'
    task compile_docs: :environment do
      renderer = Gitlab::Graphql::Docs::Renderer.new(GitlabSchema.graphql_definition, render_options)

      renderer.render

      puts "Documentation compiled."
    end
  end
end

def render_options
  {
    output_dir: OUTPUT_DIR,
    template: Rails.root.join(TEMPLATES_DIR, 'default.md.haml')
  }
end
