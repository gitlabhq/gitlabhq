module IssuableLinks
  def index
    render json: issues
  end

  def create
    result = create_service.execute

    render json: { message: result[:message], issues: issues }, status: result[:http_status]
  end

  def destroy
    result = destroy_service.execute

    render json: { issues: issues }, status: result[:http_status]
  end

  private

  def create_params
    params.slice(:issue_references)
  end

  def create_service
    raise NotImplementedError
  end

  def destroy_service
    raise NotImplementedError
  end
end
