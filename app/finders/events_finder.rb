# frozen_string_literal: true

class EventsFinder
  prepend FinderMethods
  prepend FinderWithCrossProjectAccess

  MAX_PER_PAGE = 100

  attr_reader :source, :params, :current_user, :scope

  requires_cross_project_access unless: -> { source.is_a?(Project) }, model: Event

  # Used to filter Events
  #
  # Arguments:
  #   source - which user or project to looks for events on
  #   current_user - only return events for projects visible to this user
  #   scope - return all events across a user's projects
  #   params:
  #     action: string
  #     target_type: string
  #     before: datetime
  #     after: datetime
  #     per_page: integer (max. 100)
  #     page: integer
  #     with_associations: boolean
  #     sort: 'asc' or 'desc'
  def initialize(params = {})
    @source = params.delete(:source)
    @current_user = params.delete(:current_user)
    @scope = params.delete(:scope)
    @params = params
  end

  def execute
    events = get_events

    events = by_current_user_access(events)
    events = by_action(events)
    events = by_target_type(events)
    events = by_created_at_before(events)
    events = by_created_at_after(events)
    events = sort(events)

    events = events.with_associations if params[:with_associations]

    paginated_filtered_by_user_visibility(events)
  end

  private

  def get_events
    return EventCollection.new(current_user.authorized_projects).all_project_events if scope == 'all'

    source.events
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def by_current_user_access(events)
    events.merge(Project.public_or_visible_to_user(current_user))
      .joins(:project)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def by_action(events)
    return events unless Event::ACTIONS[params[:action]]

    events.where(action: Event::ACTIONS[params[:action]])
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def by_target_type(events)
    return events unless Event::TARGET_TYPES[params[:target_type]]

    events.where(target_type: Event::TARGET_TYPES[params[:target_type]].name)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def by_created_at_before(events)
    return events unless params[:before]

    events.where('events.created_at < ?', params[:before].beginning_of_day)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def by_created_at_after(events)
    return events unless params[:after]

    events.where('events.created_at > ?', params[:after].end_of_day)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def sort(events)
    return events unless params[:sort]

    if params[:sort] == 'asc'
      events.order_id_asc
    else
      events.order_id_desc
    end
  end

  def paginated_filtered_by_user_visibility(events)
    limited_events = events.page(page).per(per_page)
    visible_events = limited_events.select { |event| event.visible_to_user?(current_user) }

    Kaminari.paginate_array(visible_events, total_count: events.count)
  end

  def per_page
    return MAX_PER_PAGE unless params[:per_page]

    [params[:per_page], MAX_PER_PAGE].min
  end

  def page
    params[:page] || 1
  end
end
