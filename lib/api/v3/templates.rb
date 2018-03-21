module API
  module V3
    class Templates < Grape::API
      GLOBAL_TEMPLATE_TYPES = {
        gitignores: {
          klass: Gitlab::Template::GitignoreTemplate,
          gitlab_version: 8.8
        },
        gitlab_ci_ymls: {
          klass: Gitlab::Template::GitlabCiYmlTemplate,
          gitlab_version: 8.9
        },
        dockerfiles: {
          klass: Gitlab::Template::DockerfileTemplate,
          gitlab_version: 8.15
        }
      }.freeze
      PROJECT_TEMPLATE_REGEX =
        %r{[\<\{\[]
          (project|description|
          one\sline\s.+\swhat\sit\sdoes\.) # matching the start and end is enough here
        [\>\}\]]}xi.freeze
      YEAR_TEMPLATE_REGEX = /[<{\[](year|yyyy)[>}\]]/i.freeze
      FULLNAME_TEMPLATE_REGEX =
        %r{[\<\{\[]
          (fullname|name\sof\s(author|copyright\sowner))
        [\>\}\]]}xi.freeze
      DEPRECATION_MESSAGE = ' This endpoint is deprecated and has been removed in V4.'.freeze

      helpers do
        def parsed_license_template
          # We create a fresh Licensee::License object since we'll modify its
          # content in place below.
          template = Licensee::License.new(params[:name])

          template.content.gsub!(YEAR_TEMPLATE_REGEX, Time.now.year.to_s)
          template.content.gsub!(PROJECT_TEMPLATE_REGEX, params[:project]) if params[:project].present?

          fullname = params[:fullname].presence || current_user.try(:name)
          template.content.gsub!(FULLNAME_TEMPLATE_REGEX, fullname) if fullname
          template
        end

        def render_response(template_type, template)
          not_found!(template_type.to_s.singularize) unless template
          present template, with: ::API::Entities::Template
        end
      end

      { "licenses" => :deprecated, "templates/licenses" => :ok }.each do |route, status|
        desc 'Get the list of the available license template' do
          detailed_desc = 'This feature was introduced in GitLab 8.7.'
          detailed_desc << DEPRECATION_MESSAGE unless status == :ok
          detail detailed_desc
          success ::API::Entities::License
        end
        params do
          optional :popular, type: Boolean, desc: 'If passed, returns only popular licenses'
        end
        get route do
          options = {
            featured: declared(params)[:popular].present? ? true : nil
          }
          present Licensee::License.all(options), with: ::API::Entities::License
        end
      end

      { "licenses/:name" => :deprecated, "templates/licenses/:name" => :ok }.each do |route, status|
        desc 'Get the text for a specific license' do
          detailed_desc = 'This feature was introduced in GitLab 8.7.'
          detailed_desc << DEPRECATION_MESSAGE unless status == :ok
          detail detailed_desc
          success ::API::Entities::License
        end
        params do
          requires :name, type: String, desc: 'The name of the template'
        end
        get route, requirements: { name: /[\w\.-]+/ } do
          not_found!('License') unless Licensee::License.find(declared(params)[:name])

          template = parsed_license_template

          present template, with: ::API::Entities::License
        end
      end

      GLOBAL_TEMPLATE_TYPES.each do |template_type, properties|
        klass = properties[:klass]
        gitlab_version = properties[:gitlab_version]

        { template_type => :deprecated, "templates/#{template_type}" => :ok }.each do |route, status|
          desc 'Get the list of the available template' do
            detailed_desc = "This feature was introduced in GitLab #{gitlab_version}."
            detailed_desc << DEPRECATION_MESSAGE unless status == :ok
            detail detailed_desc
            success ::API::Entities::TemplatesList
          end
          get route do
            present klass.all, with: ::API::Entities::TemplatesList
          end
        end

        { "#{template_type}/:name" => :deprecated, "templates/#{template_type}/:name" => :ok }.each do |route, status|
          desc 'Get the text for a specific template present in local filesystem' do
            detailed_desc = "This feature was introduced in GitLab #{gitlab_version}."
            detailed_desc << DEPRECATION_MESSAGE unless status == :ok
            detail detailed_desc
            success ::API::Entities::Template
          end
          params do
            requires :name, type: String, desc: 'The name of the template'
          end
          get route do
            new_template = klass.find(declared(params)[:name])

            render_response(template_type, new_template)
          end
        end
      end
    end
  end
end
