# frozen_string_literal: true

# LicenseTemplateFinder
#
# Used to find license templates, which may come from a variety of external
# sources
#
# Arguments:
#   popular: boolean. When set to true, only "popular" licenses are shown. When
#            false, all licenses except popular ones are shown. When nil (the
#            default), *all* licenses will be shown.
class LicenseTemplateFinder
  attr_reader :params

  def initialize(params = {})
    @params = params
  end

  def execute
    Licensee::License.all(featured: popular_only?).map do |license|
      LicenseTemplate.new(
        id: license.key,
        name: license.name,
        nickname: license.nickname,
        category: (license.featured? ? :Popular : :Other),
        content: license.content,
        url: license.url,
        meta: license.meta
      )
    end
  end

  private

  def popular_only?
    params.fetch(:popular, nil)
  end
end
