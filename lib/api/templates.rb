module API
  class Templates < Grape::API
    include PaginationParams

    GLOBAL_TEMPLATE_TYPES = {
      gitignores: {
        gitlab_version: 8.8
      },
      gitlab_ci_ymls: {
        gitlab_version: 8.9
      },
      dockerfiles: {
        gitlab_version: 8.15
      }
    }.freeze

    helpers do
      def render_response(template_type, template)
        not_found!(template_type.to_s.singularize) unless template
        present template, with: Entities::Template
      end
    end

    desc 'Get the list of the available license template' do
      detail 'This feature was introduced in GitLab 8.7.'
      success ::API::Entities::License
    end
    params do
      optional :popular, type: Boolean, desc: 'If passed, returns only popular licenses'
      use :pagination
    end
    get "templates/licenses" do
      popular = declared(params)[:popular]
      popular = to_boolean(popular) if popular.present?

      templates = LicenseTemplateFinder.new(popular: popular).execute

      present paginate(::Kaminari.paginate_array(templates)), with: ::API::Entities::License
    end

    desc 'Get the text for a specific license' do
      detail 'This feature was introduced in GitLab 8.7.'
      success ::API::Entities::License
    end
    params do
      requires :name, type: String, desc: 'The name of the template'
    end
    get "templates/licenses/:name", requirements: { name: /[\w\.-]+/ } do
      templates = LicenseTemplateFinder.new.execute
      template = templates.find { |template| template.key == params[:name] }

      not_found!('License') unless template.present?

      template.resolve!(
        project_name: params[:project].presence,
        fullname: params[:fullname].presence || current_user&.name
      )

      present template, with: ::API::Entities::License
    end

    GLOBAL_TEMPLATE_TYPES.each do |template_type, properties|
      gitlab_version = properties[:gitlab_version]

      desc 'Get the list of the available template' do
        detail "This feature was introduced in GitLab #{gitlab_version}."
        success Entities::TemplatesList
      end
      params do
        use :pagination
      end
      get "templates/#{template_type}" do
        templates = ::Kaminari.paginate_array(TemplateFinder.new(template_type).execute)
        present paginate(templates), with: Entities::TemplatesList
      end

      desc 'Get the text for a specific template present in local filesystem' do
        detail "This feature was introduced in GitLab #{gitlab_version}."
        success Entities::Template
      end
      params do
        requires :name, type: String, desc: 'The name of the template'
      end
      get "templates/#{template_type}/:name" do
        finder = TemplateFinder.new(template_type, name: declared(params)[:name])
        new_template = finder.execute

        render_response(template_type, new_template)
      end
    end
  end
end
