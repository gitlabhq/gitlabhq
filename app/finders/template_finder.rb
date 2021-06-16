# frozen_string_literal: true

class TemplateFinder
  include Gitlab::Utils::StrongMemoize

  VENDORED_TEMPLATES = HashWithIndifferentAccess.new(
    dockerfiles: ::Gitlab::Template::DockerfileTemplate,
    gitignores: ::Gitlab::Template::GitignoreTemplate,
    gitlab_ci_ymls: ::Gitlab::Template::GitlabCiYmlTemplate,
    metrics_dashboard_ymls: ::Gitlab::Template::MetricsDashboardTemplate,
    issues: ::Gitlab::Template::IssueTemplate,
    merge_requests: ::Gitlab::Template::MergeRequestTemplate
  ).freeze

  class << self
    def build(type, project, params = {})
      if type.to_s == 'licenses'
        LicenseTemplateFinder.new(project, params) # rubocop: disable CodeReuse/Finder
      else
        new(type, project, params)
      end
    end

    def all_template_names(project, type)
      return {} if !VENDORED_TEMPLATES.key?(type.to_s) && type.to_s != 'licenses'

      build(type, project).template_names
    end
  end

  attr_reader :type, :project, :params

  attr_reader :vendored_templates
  private :vendored_templates

  def initialize(type, project, params = {})
    @type = type
    @project = project
    @params = params

    @vendored_templates = VENDORED_TEMPLATES.fetch(type)
  end

  def execute
    if params[:name]
      vendored_templates.find(params[:name], project)
    else
      vendored_templates.all(project)
    end
  end

  def template_names
    vendored_templates.template_names(project)
  end
end

TemplateFinder.prepend_mod_with('TemplateFinder')
