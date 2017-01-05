class PipelineSerializer < BaseSerializer
  entity PipelineEntity
  class InvalidResourceError < StandardError; end
  include API::Helpers::Pagination
  Struct.new('Pagination', :request, :response)

  def represent(resource, opts = {})
    if paginated?
      raise InvalidResourceError unless resource.respond_to?(:page)

      super(paginate(resource.includes(project: :namespace)), opts)
    else
      super(resource, opts)
    end
  end

  def paginated?
    defined?(@pagination)
  end

  def with_pagination(request, response)
    tap { @pagination = Struct::Pagination.new(request, response) }
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
