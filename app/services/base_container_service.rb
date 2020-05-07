# frozen_string_literal: true

# Base class, scoped by container (project or group)
class BaseContainerService
  include BaseServiceUtility

  attr_reader :container, :current_user, :params

  def initialize(container:, current_user: nil, params: {})
    @container, @current_user, @params = container, current_user, params.dup
  end
end
