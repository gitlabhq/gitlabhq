# frozen_string_literal: true

# LicenseTemplateFinder
#
# Used to find license templates, which may come from a variety of external
# sources
#
# Params can be any of the following:
#   popular: boolean. When set to true, only "popular" licenses are shown. When
#            false, all licenses except popular ones are shown. When nil (the
#            default), *all* licenses will be shown.
#   name:    string. If set, return a single license matching that name (or nil)
class LicenseTemplateFinder
  include Gitlab::Utils::StrongMemoize

  attr_reader :project, :params

  def initialize(project, params = {})
    @project = project
    @params = params
  end

  def execute
    if params[:name]
      vendored_licenses.find { |template| template.key == params[:name] }
    else
      vendored_licenses
    end
  end

  private

  def vendored_licenses
    strong_memoize(:vendored_licenses) do
      Licensee::License.all(featured: popular_only?).map do |license|
        LicenseTemplate.new(
          key: license.key,
          name: license.name,
          nickname: license.nickname,
          category: (license.featured? ? :Popular : :Other),
          content: license.content,
          url: license.url,
          meta: license.meta
        )
      end
    end
  end

  def popular_only?
    params.fetch(:popular, nil)
  end
end

LicenseTemplateFinder.prepend_if_ee('::EE::LicenseTemplateFinder')
