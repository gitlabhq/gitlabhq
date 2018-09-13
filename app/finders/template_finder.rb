class TemplateFinder
  prepend ::EE::TemplateFinder

  VENDORED_TEMPLATES = {
    dockerfiles: ::Gitlab::Template::DockerfileTemplate,
    gitignores: ::Gitlab::Template::GitignoreTemplate,
    gitlab_ci_ymls: ::Gitlab::Template::GitlabCiYmlTemplate
  }.freeze

  class << self
    def build(type, params = {})
      if type == :licenses
        LicenseTemplateFinder.new(params) # rubocop: disable CodeReuse/Finder
      else
        new(type, params)
      end
    end
  end

  attr_reader :type, :params

  attr_reader :vendored_templates
  private :vendored_templates

  def initialize(type, params = {})
    @type = type
    @params = params

    @vendored_templates = VENDORED_TEMPLATES.fetch(type)
  end

  def execute
    if params[:name]
      vendored_templates.find(params[:name])
    else
      vendored_templates.all
    end
  end
end
