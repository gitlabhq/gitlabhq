# frozen_string_literal: true

module API
  class ProjectTemplates < Grape::API
    include PaginationParams

    TEMPLATE_TYPES = %w[dockerfiles gitignores gitlab_ci_ymls licenses].freeze

    before { authenticate_non_get! }

    params do
      requires :id, type: String, desc: 'The ID of a project'
      requires :type, type: String, values: TEMPLATE_TYPES, desc: 'The type (dockerfiles|gitignores|gitlab_ci_ymls|licenses) of the template'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get a list of templates available to this project' do
        detail 'This endpoint was introduced in GitLab 11.4'
      end
      params do
        use :pagination
      end
      get ':id/templates/:type' do
        templates = TemplateFinder
          .build(params[:type], user_project)
          .execute

        present paginate(::Kaminari.paginate_array(templates)), with: Entities::TemplatesList
      end

      desc 'Download a template available to this project' do
        detail 'This endpoint was introduced in GitLab 11.4'
      end
      params do
        requires :name, type: String, desc: 'The name of the template'

        optional :project, type: String, desc: 'The project name to use when expanding placeholders in the template. Only affects licenses'
        optional :fullname, type: String, desc: 'The full name of the copyright holder to use when expanding placeholders in the template. Only affects licenses'
      end
      # The regex is needed to ensure a period (e.g. agpl-3.0)
      # isn't confused with a format type. We also need to allow encoded
      # values (e.g. C%2B%2B for C++), so allow % and + as well.
      get ':id/templates/:type/:name', requirements: { name: /[\w%.+-]+/ } do
        template = TemplateFinder
          .build(params[:type], user_project, name: params[:name])
          .execute

        not_found!('Template') unless template.present?

        template.resolve!(
          project_name: params[:project].presence,
          fullname: params[:fullname].presence || current_user&.name
        )

        if template.is_a?(::LicenseTemplate)
          present template, with: Entities::License
        else
          present template, with: Entities::Template
        end
      end
    end
  end
end
