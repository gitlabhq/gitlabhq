class LogFinder
  PER_PAGE = 25
  ENTITY_COLUMN_TYPES = {
    'User' => :user_id,
    'Group' => :group_id,
    'Project' => :project_id
  }.freeze

  def initialize(params)
    @params = params
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def execute
    AuditEvent.order(id: :desc).where(conditions).page(@params[:page]).per(PER_PAGE)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  def conditions
    return nil unless entity_column

    { entity_type: @params[:event_type] }.tap do |hash|
      hash[:entity_id] = @params[entity_column] if entity_present?
    end
  end

  def entity_column
    @entity_column ||= ENTITY_COLUMN_TYPES[@params[:event_type]]
  end

  def entity_present?
    @params[entity_column] && @params[entity_column] != '0'
  end
end
