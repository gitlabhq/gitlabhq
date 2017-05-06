class JobGroupEntity < Grape::Entity
  include RequestAwareEntity

  expose :name
  expose :size
  expose :detailed_status, as: :status, with: StatusEntity
  expose :jobs, with: BuildEntity

  private

  alias_method :group, :object

  def detailed_status
    group.detailed_status(request.user)
  end
end
