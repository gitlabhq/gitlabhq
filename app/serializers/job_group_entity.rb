# frozen_string_literal: true

class JobGroupEntity < Grape::Entity
  include RequestAwareEntity

  expose :name
  expose :size
  expose :detailed_status, as: :status, with: DetailedStatusEntity
  expose :jobs, with: JobEntity

  expose :scheduled_at do |group|
    (Time.now + 30.minutes).utc.iso8601
  end

  private

  alias_method :group, :object

  def detailed_status
    group.detailed_status(request.current_user)
  end
end
