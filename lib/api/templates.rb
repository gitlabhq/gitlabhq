module API
  class Templates < Grape::API
    GLOBAL_TEMPLATE_TYPES = {
      gitignores:     Gitlab::Template::GitignoreTemplate,
      gitlab_ci_ymls: Gitlab::Template::GitlabCiYmlTemplate
    }.freeze

    helpers do
      def render_response(template_type, template)
        not_found!(template_type.to_s.singularize) unless template
        present template, with: Entities::Template
      end
    end

    GLOBAL_TEMPLATE_TYPES.each do |template_type, klass|
      # Get the list of the available template
      #
      # Example Request:
      #   GET /gitignores
      #   GET /gitlab_ci_ymls
      get template_type.to_s do
        present klass.all, with: Entities::TemplatesList
      end

      # Get the text for a specific template present in local filesystem
      #
      # Parameters:
      #   name (required) - The name of a template
      #
      # Example Request:
      #   GET /gitignores/Elixir
      #   GET /gitlab_ci_ymls/Ruby
      get "#{template_type}/:name" do
        required_attributes! [:name]
        new_template = klass.find(params[:name])
        render_response(template_type, new_template)
      end
    end
  end
end
