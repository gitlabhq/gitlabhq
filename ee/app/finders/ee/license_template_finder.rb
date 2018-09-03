module EE
  module LicenseTemplateFinder
    include ::Gitlab::Utils::StrongMemoize
    extend ::Gitlab::Utils::Override

    override :execute
    def execute
      return super unless custom_templates?

      extra = custom_licenses.map do |template|
        LicenseTemplate.new(
          id: template.name,
          name: template.name,
          nickname: template.name,
          category: :Custom,
          content: -> { template.content }
        )
      end

      extra.push(*super)
    end

    private

    def custom_templates?
      !popular_only? &&
        ::License.feature_available?(:custom_file_templates) &&
        template_project.present?
    end

    def custom_licenses
      ::Gitlab::Template::CustomLicenseTemplate.all(template_project)
    end

    def template_project
      strong_memoize(:template_project) { ::Gitlab::CurrentSettings.file_template_project }
    end
  end
end
