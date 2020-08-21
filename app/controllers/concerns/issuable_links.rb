# frozen_string_literal: true

module IssuableLinks
  def index
    render json: issuables
  end

  def create
    result = create_service.execute

    render json: { message: result[:message], issuables: issuables }, status: result[:http_status]
  end

  def destroy
    result = destroy_service.execute

    render json: { issuables: issuables }, status: result[:http_status]
  end

  private

  def issuables
    list_service.execute
  end

  def list_service
    raise NotImplementedError
  end

  def create_params
    params.permit(issuable_references: [])
  end

  def create_service
    raise NotImplementedError
  end

  def destroy_service
    raise NotImplementedError
  end
end
