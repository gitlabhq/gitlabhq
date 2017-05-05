class JobEntity < Grape::Entity
  include RequestAwareEntity

  expose :name
  expose :detailed_status, as: :status, with: StatusEntity

  private

  alias_method :job, :object

  def detailed_status
    job.detailed_status(request.user)
  end
end
