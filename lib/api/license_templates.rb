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

    # Get the list of the available license templates
    #
    # Parameters:
    #   popular - Filter licenses to only the popular ones
    #
    # Example Request:
    #   GET /licenses
    #   GET /licenses?popular=1
    get 'licenses' do
      options = {
        featured: params[:popular].present? ? true : nil
      }
      present Licensee::License.all(options), with: Entities::RepoLicense
    end

    # Get text for specific license
    #
    # Parameters:
    #   key (required) - The key of a license
    #   project        - Copyrighted project name
    #   fullname       - Full name of copyright holder
    #
    # Example Request:
    #   GET /licenses/mit
    #
    get 'licenses/:key', requirements: { key: /[\w\.-]+/ } do
      required_attributes! [:key]

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
