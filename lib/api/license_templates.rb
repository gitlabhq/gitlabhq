module API
  # License Templates API
  class LicenseTemplates < Grape::API
    PROJECT_TEMPLATE_REGEX =
      /[\<\{\[]
        (project|description|
        one\sline\s.+\swhat\sit\sdoes\.) # matching the start and end is enough here
      [\>\}\]]/xi.freeze
    YEAR_TEMPLATE_REGEX = /[<{\[](year|yyyy)[>}\]]/i.freeze
    FULLNAME_TEMPLATE_REGEX =
      /[\<\{\[]
        (fullname|name\sof\s(author|copyright\sowner))
      [\>\}\]]/xi.freeze

    desc 'Get the list of the available license templates' do
      success Entities::RepoLicense
    end
    params do
      optional :popular, type: String, desc: 'Filter licenses to only the popular ones'
    end
    get 'licenses' do
      options = {
        featured: params[:popular].present? ? true : nil
      }
      present Licensee::License.all(options), with: Entities::RepoLicense
    end

    desc 'Get text for specific license' do
      success Entities::RepoLicense
    end
    params do
      requires :key, type: String, regexp: /[\w\.-]+/, desc: 'The key of a license'
      optional :project, type: String, desc: 'Copyrighted project name'
      optional :fullname, type: String, desc: 'Full name of copyright holder'
    end
    get 'licenses/:key' do
      not_found!('License') unless Licensee::License.find(params[:key])

      # We create a fresh Licensee::License object since we'll modify its
      # content in place below.
      license = Licensee::License.new(params[:key])

      license.content.gsub!(YEAR_TEMPLATE_REGEX, Time.now.year.to_s)
      license.content.gsub!(PROJECT_TEMPLATE_REGEX, params[:project]) if params[:project].present?

      fullname = params[:fullname].presence || current_user.try(:name)
      license.content.gsub!(FULLNAME_TEMPLATE_REGEX, fullname) if fullname

      present license, with: Entities::RepoLicense
    end
  end
end
