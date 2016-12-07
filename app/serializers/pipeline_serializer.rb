class PipelineSerializer < BaseSerializer
  entity PipelineEntity
  include API::Helpers::Pagination
  Struct.new('Pagination', :request, :response)

  def with_pagination(request, response)
    tap { @pagination = Struct::Pagination.new(request, response) }
  end

  def paginate?
    defined?(@pagination)
  end

  def represent(resource, opts = {})
    if paginate?
      super(paginate(resource), opts)
    else
      super(resource, opts)
    end
  end

  private

  # Methods needed by `API::Helpers::Pagination`
  #
  def params
    @pagination.request.query_parameters
  end

  def request
    @pagination.request
  end

  def header(header, value)
    @pagination.response.headers[header] = value
  end
end
