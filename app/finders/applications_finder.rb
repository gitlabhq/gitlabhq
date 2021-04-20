# frozen_string_literal: true

class ApplicationsFinder
  attr_reader :params

  def initialize(params = {})
    @params = params
  end

  def execute
    applications = Doorkeeper::Application.where(owner_id: nil) # rubocop: disable CodeReuse/ActiveRecord
    by_id(applications)
  end

  private

  def by_id(applications)
    return applications unless params[:id]

    applications.find_by(id: params[:id]) # rubocop: disable CodeReuse/ActiveRecord
  end
end
