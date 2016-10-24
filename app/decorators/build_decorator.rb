class BuildDecorator < SimpleDelegator
  def initialize(build, user)
    super(build)

    @build, @user = build, user
  end

  def erased_by_user?
    # Build can be erased through API, therefore it does not have
    # `erase_by` user assigned in that case.
    erased? && erased_by
  end

  def erased_by_name
    erased_by.name if erased_by
  end

  def coverage_visible?
    !!coverage
  end

  def artifacts_visible?
    Ability.allowed?(@user, :read_build, project) &&
      (artifacts? || artifacts_expired?)
  end

  def retry_visible?
    Ability.allowed?(@user, :update_build, @build) && retryable?
  end

  def erase_visible?
    Ability.allowed?(@user, :update_build, project) && erasable?
  end

  def details_block_first?
    !(coverage_visible? || artifacts_visible?)
  end

  def link_to_runner_administration_visible?
    runner && @user && @user.admin
  end

  def trigger_request_short_token
    trigger_request.trigger.short_token
  end

  def self.ancestors
    super + [Ci::Build]
  end
end
