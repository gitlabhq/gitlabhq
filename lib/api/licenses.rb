module API
  # Licenses API
  class Licenses < Grape::API
    YEAR_TEMPLATE_REGEX = /(\[|<|{)(year|yyyy)(\]|>|})/
    FULLNAME_TEMPLATE_REGEX = /\[fullname\]/

    # Get text for specific license
    #
    # Parameters:
    #   key (required) - The key of a license
    #   fullname       - Reository owner fullname
    # Example Request:
    #   GET /licenses/mit
    get 'licenses/:key', requirements: { key: /[\w.-]*/ } do
      env['api.format'] = :txt
      license = Licensee::License.find(params[:key]).try(:text)

      if license
        license
          .gsub(YEAR_TEMPLATE_REGEX, Time.now.year.to_s)
          .gsub(FULLNAME_TEMPLATE_REGEX, params[:fullname])
      else
        error!('License not found', 404)
      end
    end
  end
end
