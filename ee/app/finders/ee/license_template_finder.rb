module EE
  module LicenseTemplateFinder
    extend ::Gitlab::Utils::Override

    override :execute
    def execute
      return super unless custom_templates?

      if params[:name]
        custom_template || super
      else
        custom_templates + super
      end
    end

    private

    def custom_templates
      templates_for(template_project).map do |template|
        translate(template, category: :Custom)
      end
    end

    def custom_template
      template = template_for(template_project, params[:name])

      translate(template, category: :Custom)
    rescue ::Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError
      nil
    end

    def custom_templates?
      !popular_only? &&
        ::License.feature_available?(:custom_file_templates) &&
        template_project.present?
    end

    def template_project
      strong_memoize(:template_project) { ::Gitlab::CurrentSettings.file_template_project }
    end

    def templates_for(project)
      return [] unless project

      ::Gitlab::Template::CustomLicenseTemplate.all(project)
    end

    def template_for(project, name)
      return unless project

      ::Gitlab::Template::CustomLicenseTemplate.find(name, project)
    end

    def translate(template, category:)
      return unless template

      LicenseTemplate.new(
        key: template.key,
        name: template.name,
        nickname: template.name,
        category: category,
        content: -> { template.content }
      )
    end
  end
end
