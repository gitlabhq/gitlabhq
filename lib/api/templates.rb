# frozen_string_literal: true

module API
  class Templates < ::API::Base
    include PaginationParams

    GLOBAL_TEMPLATE_TYPES = {
      gitignores: {
        gitlab_version: 8.8,
        feature_category: :source_code_management,
        file_type: '.gitignore'
      },
      gitlab_ci_ymls: {
        gitlab_version: 8.9,
        feature_category: :pipeline_composition,
        file_type: 'GitLab CI/CD YAML'
      },
      dockerfiles: {
        gitlab_version: 8.15,
        feature_category: :source_code_management,
        file_type: 'Dockerfile'
      }
    }.freeze

    helpers do
      def render_response(template_type, template)
        not_found!(template_type.to_s.singularize) unless template
        present template, with: Entities::Template
      end
    end

    desc 'List all license templates' do
      detail 'Lists all available license templates.'
      success ::API::Entities::License
      tags ['templates']
    end
    params do
      optional :popular, type: Boolean, desc: 'If passed, returns only popular licenses'
      use :pagination
    end

    route_setting :authorization, skip_granular_token_authorization: :public_endpoint
    get "templates/licenses", feature_category: :source_code_management do
      popular = declared(params)[:popular]
      popular = to_boolean(popular) if popular.present?

      templates = TemplateFinder.build(:licenses, nil, popular: popular).execute

      present paginate(::Kaminari.paginate_array(templates)), with: ::API::Entities::License
    end

    desc 'Retrieve a license template' do
      detail 'Retrieves a specified license template. You can pass parameters to replace the license placeholder.'
      success ::API::Entities::License
      tags ['templates']
    end
    params do
      requires :name, type: String, desc: 'The name of the license template'
      optional :project, type: String, desc: 'The copyrighted project name'
      optional :fullname, type: String, desc: 'The full-name of the copyright holder'
    end

    route_setting :authorization, skip_granular_token_authorization: :public_endpoint
    get "templates/licenses/:name", requirements: { name: /[\w\.-]+/ }, feature_category: :source_code_management do
      template = TemplateFinder.build(:licenses, nil, name: params[:name]).execute

      not_found!('License') unless template.present?

      template.resolve!(
        project_name: params[:project].presence,
        fullname: params[:fullname].presence || current_user&.name
      )

      present template, with: ::API::Entities::License
    end

    GLOBAL_TEMPLATE_TYPES.each do |template_type, properties|
      file_type = properties[:file_type]

      desc "List all #{file_type} templates" do
        detail "Lists all #{file_type} templates."
        success Entities::TemplatesList
        tags ['templates']
      end
      params do
        use :pagination
      end

      route_setting :authorization, skip_granular_token_authorization: :public_endpoint
      get "templates/#{template_type}", feature_category: properties[:feature_category] do
        templates = ::Kaminari.paginate_array(TemplateFinder.build(template_type, nil).execute)
        present paginate(templates), with: Entities::TemplatesList
      end

      desc "Retrieve a #{file_type} template" do
        detail "Retrieves a specified #{file_type} template."
        success Entities::Template
        tags ['templates']
      end
      params do
        requires :name, type: String, desc: "The name of the #{file_type} template"
      end

      route_setting :authorization, skip_granular_token_authorization: :public_endpoint
      get "templates/#{template_type}/:name", requirements: { name: /[\w\.-]+/ }, feature_category: properties[:feature_category] do
        finder = TemplateFinder.build(template_type, nil, name: declared(params)[:name])
        new_template = finder.execute

        render_response(template_type, new_template)
      end
    end
  end
end
