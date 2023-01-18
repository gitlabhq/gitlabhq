# frozen_string_literal: true

class AccessRequestsFinder
  attr_accessor :source

  # Arguments:
  #   source - a Group or Project
  def initialize(source)
    @source = source
  end

  def execute(*args)
    execute!(*args)
  rescue Gitlab::Access::AccessDeniedError
    []
  end

  def execute!(current_user)
    raise Gitlab::Access::AccessDeniedError unless can_see_access_requests?(current_user)

    if Feature.enabled?(:project_members_index_by_project_namespace, source)
      source.namespace_requesters
    else
      source.requesters
    end
  end

  private

  def can_see_access_requests?(current_user)
    source && Ability.allowed?(current_user, :admin_member_access_request, source)
  end
end
