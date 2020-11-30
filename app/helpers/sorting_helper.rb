# frozen_string_literal: true

module SortingHelper
  def sort_options_hash
    {
      sort_value_created_date      => sort_title_created_date,
      sort_value_downvotes         => sort_title_downvotes,
      sort_value_due_date          => sort_title_due_date,
      sort_value_due_date_later    => sort_title_due_date_later,
      sort_value_due_date_soon     => sort_title_due_date_soon,
      sort_value_label_priority    => sort_title_label_priority,
      sort_value_largest_group     => sort_title_largest_group,
      sort_value_largest_repo      => sort_title_largest_repo,
      sort_value_milestone         => sort_title_milestone,
      sort_value_milestone_later   => sort_title_milestone_later,
      sort_value_milestone_soon    => sort_title_milestone_soon,
      sort_value_name              => sort_title_name,
      sort_value_name_desc         => sort_title_name_desc,
      sort_value_oldest_created    => sort_title_oldest_created,
      sort_value_oldest_signin     => sort_title_oldest_signin,
      sort_value_oldest_updated    => sort_title_oldest_updated,
      sort_value_recently_created  => sort_title_recently_created,
      sort_value_recently_signin   => sort_title_recently_signin,
      sort_value_recently_updated  => sort_title_recently_updated,
      sort_value_popularity        => sort_title_popularity,
      sort_value_priority          => sort_title_priority,
      sort_value_upvotes           => sort_title_upvotes,
      sort_value_contacted_date    => sort_title_contacted_date,
      sort_value_relative_position => sort_title_relative_position,
      sort_value_size              => sort_title_size,
      sort_value_expire_date       => sort_title_expire_date,
      sort_value_relevant          => sort_title_relevant
    }
  end

  def projects_sort_options_hash
    use_old_sorting = Feature.disabled?(:project_list_filter_bar) || current_controller?('admin/projects')

    options = {
      sort_value_latest_activity  => sort_title_latest_activity,
      sort_value_recently_created => sort_title_created_date,
      sort_value_name             => sort_title_name,
      sort_value_name_desc        => sort_title_name_desc,
      sort_value_stars_desc       => sort_title_stars
    }

    if use_old_sorting
      options = options.merge({
        sort_value_oldest_activity  => sort_title_oldest_activity,
        sort_value_oldest_created   => sort_title_oldest_created,
        sort_value_recently_created => sort_title_recently_created,
        sort_value_stars_desc       => sort_title_most_stars
      })
    end

    if current_controller?('admin/projects')
      options[sort_value_largest_repo] = sort_title_largest_repo
    end

    options
  end

  def projects_sort_option_titles
    # Only used for the project filter search bar
    projects_sort_options_hash.merge({
      sort_value_oldest_activity  => sort_title_latest_activity,
      sort_value_oldest_created   => sort_title_created_date,
      sort_value_name_desc        => sort_title_name,
      sort_value_stars_asc        => sort_title_stars
    })
  end

  def projects_reverse_sort_options_hash
    {
      sort_value_latest_activity  => sort_value_oldest_activity,
      sort_value_recently_created => sort_value_oldest_created,
      sort_value_name             => sort_value_name_desc,
      sort_value_stars_desc       => sort_value_stars_asc,
      sort_value_oldest_activity  => sort_value_latest_activity,
      sort_value_oldest_created   => sort_value_recently_created,
      sort_value_name_desc        => sort_value_name,
      sort_value_stars_asc        => sort_value_stars_desc
    }
  end

  def search_reverse_sort_options_hash
    {
      sort_value_recently_created => sort_value_oldest_created,
      sort_value_oldest_created   => sort_value_recently_created
    }
  end

  def groups_sort_options_hash
    {
      sort_value_name             => sort_title_name,
      sort_value_name_desc        => sort_title_name_desc,
      sort_value_recently_created => sort_title_recently_created,
      sort_value_oldest_created   => sort_title_oldest_created,
      sort_value_latest_activity  => sort_title_recently_updated,
      sort_value_oldest_activity  => sort_title_oldest_updated
    }
  end

  def subgroups_sort_options_hash
    groups_sort_options_hash.merge(
      sort_value_stars_desc => sort_title_most_stars
    )
  end

  def admin_groups_sort_options_hash
    groups_sort_options_hash.merge(
      sort_value_largest_group => sort_title_largest_group
    )
  end

  def member_sort_options_hash
    {
      sort_value_access_level_asc  => sort_title_access_level_asc,
      sort_value_access_level_desc => sort_title_access_level_desc,
      sort_value_last_joined       => sort_title_last_joined,
      sort_value_name              => sort_title_name_asc,
      sort_value_name_desc         => sort_title_name_desc,
      sort_value_oldest_joined     => sort_title_oldest_joined,
      sort_value_oldest_signin     => sort_title_oldest_signin,
      sort_value_recently_signin   => sort_title_recently_signin
    }
  end

  def milestone_sort_options_hash
    {
      sort_value_name             => sort_title_name_asc,
      sort_value_name_desc        => sort_title_name_desc,
      sort_value_due_date_later   => sort_title_due_date_later,
      sort_value_due_date_soon    => sort_title_due_date_soon,
      sort_value_start_date_later => sort_title_start_date_later,
      sort_value_start_date_soon  => sort_title_start_date_soon
    }
  end

  def branches_sort_options_hash
    {
      sort_value_name             => sort_title_name,
      sort_value_oldest_updated   => sort_title_oldest_updated,
      sort_value_recently_updated => sort_title_recently_updated
    }
  end

  def tags_sort_options_hash
    {
      sort_value_name             => sort_title_name,
      sort_value_oldest_updated   => sort_title_oldest_updated,
      sort_value_recently_updated => sort_title_recently_updated
    }
  end

  def label_sort_options_hash
    {
      sort_value_name => sort_title_name,
      sort_value_name_desc => sort_title_name_desc,
      sort_value_recently_created => sort_title_recently_created,
      sort_value_oldest_created => sort_title_oldest_created,
      sort_value_recently_updated => sort_title_recently_updated,
      sort_value_oldest_updated => sort_title_oldest_updated
    }
  end

  def users_sort_options_hash
    {
      sort_value_name => sort_title_name,
      sort_value_recently_signin => sort_title_recently_signin,
      sort_value_oldest_signin => sort_title_oldest_signin,
      sort_value_recently_created => sort_title_recently_created,
      sort_value_oldest_created => sort_title_oldest_created,
      sort_value_recently_updated => sort_title_recently_updated,
      sort_value_oldest_updated => sort_title_oldest_updated,
      sort_value_recently_last_activity => sort_title_recently_last_activity,
      sort_value_oldest_last_activity => sort_title_oldest_last_activity
    }
  end

  def starrers_sort_options_hash
    {
      sort_value_name => sort_title_name,
      sort_value_name_desc => sort_title_name_desc,
      sort_value_recently_created => sort_title_recently_starred,
      sort_value_oldest_created => sort_title_oldest_starred
    }
  end

  def sortable_item(item, path, sorted_by)
    link_to item, path, class: sorted_by == item ? 'is-active' : ''
  end

  def issuable_sort_option_overrides
    {
      sort_value_oldest_created => sort_value_created_date,
      sort_value_oldest_updated => sort_value_recently_updated,
      sort_value_milestone_later => sort_value_milestone,
      sort_value_due_date_later => sort_value_due_date,
      sort_value_least_popular => sort_value_popularity
    }
  end

  def issuable_reverse_sort_order_hash
    {
      sort_value_created_date => sort_value_oldest_created,
      sort_value_recently_created => sort_value_oldest_created,
      sort_value_recently_updated => sort_value_oldest_updated,
      sort_value_milestone => sort_value_milestone_later,
      sort_value_due_date => sort_value_due_date_later,
      sort_value_due_date_soon => sort_value_due_date_later,
      sort_value_popularity => sort_value_least_popular,
      sort_value_most_popular => sort_value_least_popular
    }.merge(issuable_sort_option_overrides)
  end

  def audit_logs_sort_order_hash
    {
      sort_value_recently_created => sort_title_recently_created,
      sort_value_oldest_created   => sort_title_oldest_created
    }
  end

  def issuable_sort_option_title(sort_value)
    sort_value = issuable_sort_option_overrides[sort_value] || sort_value

    sort_options_hash[sort_value]
  end

  def search_sort_option_title(sort_value)
    sort_options_hash[sort_value]
  end

  def sort_direction_icon(sort_value)
    case sort_value
    when sort_value_milestone, sort_value_due_date, /_asc\z/
      'sort-lowest'
    else
      'sort-highest'
    end
  end

  def sort_direction_button(reverse_url, reverse_sort, sort_value)
    link_class = 'btn btn-default has-tooltip reverse-sort-btn qa-reverse-sort rspec-reverse-sort'
    icon = sort_direction_icon(sort_value)
    url = reverse_url

    unless reverse_sort
      url = '#'
      link_class += ' disabled'
    end

    link_to(url, type: 'button', class: link_class, title: s_('SortOptions|Sort direction')) do
      sprite_icon(icon)
    end
  end

  def issuable_sort_direction_button(sort_value)
    reverse_sort = issuable_reverse_sort_order_hash[sort_value]
    url = page_filter_path(sort: reverse_sort)

    sort_direction_button(url, reverse_sort, sort_value)
  end

  def project_sort_direction_button(sort_value)
    reverse_sort = projects_reverse_sort_options_hash[sort_value]
    url = filter_projects_path(sort: reverse_sort)

    sort_direction_button(url, reverse_sort, sort_value)
  end

  def search_sort_direction_button(sort_value)
    reverse_sort = search_reverse_sort_options_hash[sort_value]
    url = page_filter_path(sort: reverse_sort)

    sort_direction_button(url, reverse_sort, sort_value)
  end

  # Titles.
  def sort_title_access_level_asc
    s_('SortOptions|Access level, ascending')
  end

  def sort_title_access_level_desc
    s_('SortOptions|Access level, descending')
  end

  def sort_title_created_date
    s_('SortOptions|Created date')
  end

  def sort_title_downvotes
    s_('SortOptions|Least popular')
  end

  def sort_title_due_date
    s_('SortOptions|Due date')
  end

  def sort_title_due_date_later
    s_('SortOptions|Due later')
  end

  def sort_title_due_date_soon
    s_('SortOptions|Due soon')
  end

  def sort_title_label_priority
    s_('SortOptions|Label priority')
  end

  def sort_title_largest_group
    s_('SortOptions|Largest group')
  end

  def sort_title_largest_repo
    s_('SortOptions|Largest repository')
  end

  def sort_title_last_joined
    s_('SortOptions|Last joined')
  end

  def sort_title_latest_activity
    s_('SortOptions|Last updated')
  end

  def sort_title_milestone
    s_('SortOptions|Milestone due date')
  end

  def sort_title_milestone_later
    s_('SortOptions|Milestone due later')
  end

  def sort_title_milestone_soon
    s_('SortOptions|Milestone due soon')
  end

  def sort_title_name
    s_('SortOptions|Name')
  end

  def sort_title_name_asc
    s_('SortOptions|Name, ascending')
  end

  def sort_title_name_desc
    s_('SortOptions|Name, descending')
  end

  def sort_title_oldest_activity
    s_('SortOptions|Oldest updated')
  end

  def sort_title_oldest_created
    s_('SortOptions|Oldest created')
  end

  def sort_title_oldest_joined
    s_('SortOptions|Oldest joined')
  end

  def sort_title_oldest_signin
    s_('SortOptions|Oldest sign in')
  end

  def sort_title_oldest_starred
    s_('SortOptions|Oldest starred')
  end

  def sort_title_oldest_updated
    s_('SortOptions|Oldest updated')
  end

  def sort_title_popularity
    s_('SortOptions|Popularity')
  end

  def sort_title_priority
    s_('SortOptions|Priority')
  end

  def sort_title_recently_created
    s_('SortOptions|Last created')
  end

  def sort_title_recently_signin
    s_('SortOptions|Recent sign in')
  end

  def sort_title_recently_starred
    s_('SortOptions|Recently starred')
  end

  def sort_title_recently_updated
    s_('SortOptions|Last updated')
  end

  def sort_title_start_date_later
    s_('SortOptions|Start later')
  end

  def sort_title_start_date_soon
    s_('SortOptions|Start soon')
  end

  def sort_title_upvotes
    s_('SortOptions|Most popular')
  end

  def sort_title_contacted_date
    s_('SortOptions|Last Contact')
  end

  def sort_title_most_stars
    s_('SortOptions|Most stars')
  end

  def sort_title_stars
    s_('SortOptions|Stars')
  end

  def sort_title_oldest_last_activity
    s_('SortOptions|Oldest last activity')
  end

  def sort_title_recently_last_activity
    s_('SortOptions|Recent last activity')
  end

  def sort_title_relative_position
    s_('SortOptions|Manual')
  end

  def sort_title_size
    s_('SortOptions|Size')
  end

  def sort_title_expire_date
    s_('SortOptions|Expired date')
  end

  def sort_title_relevant
    s_('SortOptions|Relevant')
  end

  # Values.
  def sort_value_access_level_asc
    'access_level_asc'
  end

  def sort_value_access_level_desc
    'access_level_desc'
  end

  def sort_value_created_date
    'created_date'
  end

  def sort_value_downvotes
    'downvotes_desc'
  end

  def sort_value_due_date
    'due_date'
  end

  def sort_value_due_date_later
    'due_date_desc'
  end

  def sort_value_due_date_soon
    'due_date_asc'
  end

  def sort_value_label_priority
    'label_priority'
  end

  def sort_value_largest_group
    'storage_size_desc'
  end

  def sort_value_largest_repo
    'storage_size_desc'
  end

  def sort_value_last_joined
    'last_joined'
  end

  def sort_value_latest_activity
    'latest_activity_desc'
  end

  def sort_value_milestone
    'milestone'
  end

  def sort_value_milestone_later
    'milestone_due_desc'
  end

  def sort_value_milestone_soon
    'milestone_due_asc'
  end

  def sort_value_name
    'name_asc'
  end

  def sort_value_name_desc
    'name_desc'
  end

  def sort_value_oldest_activity
    'latest_activity_asc'
  end

  def sort_value_oldest_created
    'created_asc'
  end

  def sort_value_oldest_signin
    'oldest_sign_in'
  end

  def sort_value_oldest_joined
    'oldest_joined'
  end

  def sort_value_oldest_updated
    'updated_asc'
  end

  def sort_value_popularity
    'popularity'
  end

  def sort_value_most_popular
    'popularity_desc'
  end

  def sort_value_least_popular
    'popularity_asc'
  end

  def sort_value_priority
    'priority'
  end

  def sort_value_recently_created
    'created_desc'
  end

  def sort_value_recently_signin
    'recent_sign_in'
  end

  def sort_value_recently_updated
    'updated_desc'
  end

  def sort_value_start_date_later
    'start_date_desc'
  end

  def sort_value_start_date_soon
    'start_date_asc'
  end

  def sort_value_upvotes
    'upvotes_desc'
  end

  def sort_value_contacted_date
    'contacted_asc'
  end

  def sort_value_stars_desc
    'stars_desc'
  end

  def sort_value_stars_asc
    'stars_asc'
  end

  def sort_value_oldest_last_activity
    'last_activity_on_asc'
  end

  def sort_value_recently_last_activity
    'last_activity_on_desc'
  end

  def sort_value_relative_position
    'relative_position'
  end

  def sort_value_size
    'size_desc'
  end

  def sort_value_expire_date
    'expired_asc'
  end

  def sort_value_relevant
    'relevant'
  end

  def packages_sort_options_hash
    {
      sort_value_recently_created  => sort_title_created_date,
      sort_value_oldest_created    => sort_title_created_date,
      sort_value_name              => sort_title_name,
      sort_value_name_desc         => sort_title_name,
      sort_value_version_desc      => sort_title_version,
      sort_value_version_asc       => sort_title_version,
      sort_value_type_desc         => sort_title_type,
      sort_value_type_asc          => sort_title_type,
      sort_value_project_name_desc => sort_title_project_name,
      sort_value_project_name_asc  => sort_title_project_name
    }
  end

  def packages_reverse_sort_order_hash
    {
      sort_value_recently_created  => sort_value_oldest_created,
      sort_value_oldest_created    => sort_value_recently_created,
      sort_value_name              => sort_value_name_desc,
      sort_value_name_desc         => sort_value_name,
      sort_value_version_desc      => sort_value_version_asc,
      sort_value_version_asc       => sort_value_version_desc,
      sort_value_type_desc         => sort_value_type_asc,
      sort_value_type_asc          => sort_value_type_desc,
      sort_value_project_name_desc => sort_value_project_name_asc,
      sort_value_project_name_asc  => sort_value_project_name_desc
    }
  end

  def packages_sort_option_title(sort_value)
    packages_sort_options_hash[sort_value] || sort_title_created_date
  end

  def packages_sort_direction_button(sort_value)
    reverse_sort = packages_reverse_sort_order_hash[sort_value]
    url = package_sort_path(sort: reverse_sort)

    sort_direction_button(url, reverse_sort, sort_value)
  end
end

SortingHelper.prepend_if_ee('::EE::SortingHelper')
