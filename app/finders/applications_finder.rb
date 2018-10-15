# frozen_string_literal: true

class ApplicationsFinder
  attr_reader :params

  def initialize(params = {})
    @params = params
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def execute
    applications = Doorkeeper::Application.where("owner_id IS NULL")
    by_id(applications)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  # rubocop: disable CodeReuse/ActiveRecord
  def by_id(applications)
    return applications unless params[:id]

    Doorkeeper::Application.find_by(id: params[:id])
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
