module API
  class Templates < Grape::API
    TEMPLATE_TYPES = {
      gitignores:     Gitlab::Template::Gitignore,
      gitlab_ci_ymls: Gitlab::Template::GitlabCiYml
    }.freeze

    TEMPLATE_TYPES.each do |template, klass|
      # Get the list of the available template
      #
      # Example Request:
      #   GET /gitignores
      #   GET /gitlab_ci_ymls
      get template.to_s do
        present klass.all, with: Entities::TemplatesList
      end

      # Get the text for a specific template
      #
      # Parameters:
      #   name (required) - The name of a template
      #
      # Example Request:
      #   GET /gitignores/Elixir
      #   GET /gitlab_ci_ymls/Ruby
      get "#{template}/:name" do
        required_attributes! [:name]

        new_template = klass.find(params[:name])
        not_found!(template.to_s.singularize) unless new_template

        present new_template, with: Entities::Template
      end
    end
  end
end
