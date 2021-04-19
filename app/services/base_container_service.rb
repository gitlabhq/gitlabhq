# frozen_string_literal: true

# Base class, scoped by container (project or group)
class BaseContainerService
  include BaseServiceUtility

  attr_reader :container, :current_user, :params

  def initialize(container:, current_user: nil, params: {})
    @container = container
    @current_user = current_user
    @params = params.dup
  end
end
