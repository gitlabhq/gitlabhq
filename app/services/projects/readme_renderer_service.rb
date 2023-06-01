# frozen_string_literal: true

module Projects
  class ReadmeRendererService < BaseService
    include Rails.application.routes.url_helpers

    TEMPLATE_PATH = Rails.root.join('app', 'views', 'projects', 'readme_templates')

    def execute
      render(params[:template_name] || :default)
    end

    private

    def render(template_name)
      ERB.new(File.read(sanitized_filename(template_name)), trim_mode: '<>').result(binding)
    end

    def sanitized_filename(template_name)
      path = Gitlab::PathTraversal.check_path_traversal!("#{template_name}.md.tt")
      path = TEMPLATE_PATH.join(path).to_s
      Gitlab::PathTraversal.check_allowed_absolute_path!(path, [TEMPLATE_PATH.to_s])

      path
    end
  end
end
