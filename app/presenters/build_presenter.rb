class BuildPresenter < SimpleDelegator
  include Gitlab::View::Presenter

  presents :build

  def erased_by_user?
    # Build can be erased through API, therefore it does not have
    # `erase_by` user assigned in that case.
    erased? && erased_by
  end

  def self.ancestors
    super + [Ci::Build]
  end
end
