class AccessRequestsFinder
  attr_accessor :source

  # Arguments:
  #   source - a Group or Project
  def initialize(source)
    @source = source
  end

  def execute(current_user, raise_error: false)
    if cannot_see_access_requests?(current_user)
      raise Gitlab::Access::AccessDeniedError if raise_error

      return []
    end

    source.requesters
  end

  def execute!(current_user)
    execute(current_user, raise_error: true)
  end

  private

  def cannot_see_access_requests?(current_user)
    !source || !current_user || !current_user.can?(:"admin_#{source.class.to_s.underscore}", source)
  end
end
