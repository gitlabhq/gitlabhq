module API
  class Templates < Grape::API
    include PaginationParams

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
      options = {
        featured: declared(params)[:popular].present? ? true : nil
      }
      licences = ::Kaminari.paginate_array(Licensee::License.all(options))
      present paginate(licences), with: Entities::License
    end

    desc 'Get the text for a specific license' do
      detail 'This feature was introduced in GitLab 8.7.'
      success ::API::Entities::License
    end
    params do
      requires :name, type: String, desc: 'The name of the template'
    end
    get "templates/licenses/:name", requirements: { name: /[\w\.-]+/ } do
      not_found!('License') unless Licensee::License.find(declared(params)[:name])

      template = parsed_license_template

      present template, with: ::API::Entities::License
    end

    GLOBAL_TEMPLATE_TYPES.each do |template_type, properties|
      klass = properties[:klass]
      gitlab_version = properties[:gitlab_version]

      desc 'Get the list of the available template' do
        detail "This feature was introduced in GitLab #{gitlab_version}."
        success Entities::TemplatesList
      end
      params do
        use :pagination
      end
      get "templates/#{template_type}" do
        templates = ::Kaminari.paginate_array(klass.all)
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
        new_template = klass.find(declared(params)[:name])

        render_response(template_type, new_template)
      end
    end
  end
end
