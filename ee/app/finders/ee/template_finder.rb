module EE
  module TemplateFinder
    include ::Gitlab::Utils::StrongMemoize
    extend ::Gitlab::Utils::Override

    CUSTOM_TEMPLATES = {
      dockerfiles: ::Gitlab::Template::CustomDockerfileTemplate,
      gitignores: ::Gitlab::Template::CustomGitignoreTemplate,
      gitlab_ci_ymls: ::Gitlab::Template::CustomGitlabCiYmlTemplate
    }.freeze

    attr_reader :custom_templates
    private :custom_templates

    def initialize(type, *args, &blk)
      super

      @custom_templates = CUSTOM_TEMPLATES.fetch(type)
    end

    override :execute
    def execute
      return super unless custom_templates?

      if params[:name]
        find_custom_template || super
      else
        find_custom_templates + super
      end
    end

    private

    def find_custom_template
      custom_templates.find(params[:name], template_project)
    rescue ::Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError
      nil
    end

    def find_custom_templates
      custom_templates.all(template_project)
    end

    def custom_templates?
      ::License.feature_available?(:custom_file_templates) && template_project.present?
    end

    def template_project
      strong_memoize(:template_project) { ::Gitlab::CurrentSettings.file_template_project }
    end
  end
end
