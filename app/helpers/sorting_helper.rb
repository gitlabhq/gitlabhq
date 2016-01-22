module SortingHelper
  def sort_options_hash
    {
      sort_value_name_asc => sort_title_name_asc,
      sort_value_name_desc => sort_title_name_desc,
      sort_value_recently_updated => sort_title_recently_updated,
      sort_value_oldest_updated => sort_title_oldest_updated,
      sort_value_recently_created => sort_title_recently_created,
      sort_value_oldest_created => sort_title_oldest_created,
      sort_value_milestone_soon => sort_title_milestone_soon,
      sort_value_milestone_later => sort_title_milestone_later,
      sort_value_largest_repo => sort_title_largest_repo,
      sort_value_recently_signin => sort_title_recently_signin,
      sort_value_oldest_signin => sort_title_oldest_signin,
      sort_value_recently_active => sort_title_recently_active,
      sort_value_stars => sort_title_stars
    }
  end

  def sort_title_oldest_updated
    'Oldest updated'
  end

  def sort_title_recently_updated
    'Last updated'
  end

  def sort_title_oldest_created
    'Oldest created'
  end

  def sort_title_recently_created
    'Last created'
  end

  def sort_title_milestone_soon
    'Milestone due soon'
  end

  def sort_title_milestone_later
    'Milestone due later'
  end

  def sort_title_name
    'Name'
  end

  def sort_title_name_asc
    'Name from A to Z'
  end

  def sort_title_name_desc
    'Name from Z to A'
  end

  def sort_title_largest_repo
    'Largest repository'
  end

  def sort_title_recently_signin
    'Recent sign in'
  end

  def sort_title_oldest_signin
    'Oldest sign in'
  end

  def sort_title_recently_active
    'Recently active'
  end

  def sort_title_stars
    'Most stars'
  end

  def sort_value_oldest_updated
    'updated_asc'
  end

  def sort_value_recently_updated
    'updated_desc'
  end

  def sort_value_oldest_created
    'id_asc'
  end

  def sort_value_recently_created
    'id_desc'
  end

  def sort_value_milestone_soon
    'milestone_due_asc'
  end

  def sort_value_milestone_later
    'milestone_due_desc'
  end

  def sort_value_name_asc
    'name_asc'
  end

  def sort_value_name_desc
    'name_desc'
  end

  def sort_value_largest_repo
    'repository_size_desc'
  end

  def sort_value_recently_signin
    'recent_sign_in'
  end

  def sort_value_oldest_signin
    'oldest_sign_in'
  end

  def sort_value_recently_active
    'recently_active'
  end

  def sort_value_stars
    'stars'
  end

  def link_to_sort(label, sort_method, current_sort)
    link_to_sort_or_filter(label, keyword: 'sort', value: sort_method, current_value: current_sort)
  end

  def link_to_filter(label, filter_method, current_filter)
    link_to_sort_or_filter(label, keyword: 'filter', value: filter_method, current_value: current_filter)
  end

  private

  def link_to_sort_or_filter(label, keyword:, value:, current_value: nil)
    label ||= value.to_s.humanize
    active = currently_active_sort_or_filter?(value, current_value)

    active_class = active ? 'active' : nil

    url_params = params.reject { |k, v| k == keyword && v == value }

    link_to(url_for(url_params.merge(keyword => value)), class: active_class) do
      if active
        content_tag(:span) do
          content_tag(:i, nil, class: %w[fa fa-check]).concat(content_tag(:strong, label, class: 'item-title'))
        end
      else
        label
      end
    end
  end

  def currently_active_sort_or_filter?(value, current_value)
    current_value == value
  end
end
