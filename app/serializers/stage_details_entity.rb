class StageDetailsEntity < Grape::Entity
  include RequestAwareEntity

  expose :name

  expose :title do |stage|
    "#{stage.name}: #{detailed_status.label}"
  end

  expose :statuses, with: JobEntity

  expose :detailed_status, as: :status, with: StatusEntity

  private

  alias_method :stage, :object

  def detailed_status
    stage.detailed_status(request.current_user)
  end
end
