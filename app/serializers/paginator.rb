class Paginator
  include API::Helpers::Pagination

  def initialize(request, response)
    @request = request
    @response = response
  end

  private

  # Methods needed by `API::Helpers::Pagination`
  #

  attr_reader :request

  def params
    @request.query_parameters
  end

  def header(header, value)
    @response.headers[header] = value
  end
end
