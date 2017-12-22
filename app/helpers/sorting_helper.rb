module SortingHelper
  def sort_options_hash
    {
      sort_value_created_date     => sort_title_created_date,
      sort_value_downvotes        => sort_title_downvotes,
      sort_value_due_date         => sort_title_due_date,
      sort_value_due_date_later   => sort_title_due_date_later,
      sort_value_due_date_soon    => sort_title_due_date_soon,
      sort_value_label_priority   => sort_title_label_priority,
      sort_value_largest_group    => sort_title_largest_group,
      sort_value_largest_repo     => sort_title_largest_repo,
      sort_value_milestone        => sort_title_milestone,
      sort_value_milestone_later  => sort_title_milestone_later,
      sort_value_milestone_soon   => sort_title_milestone_soon,
      sort_value_name             => sort_title_name,
      sort_value_name_desc        => sort_title_name_desc,
      sort_value_oldest_created   => sort_title_oldest_created,
      sort_value_oldest_signin    => sort_title_oldest_signin,
      sort_value_oldest_updated   => sort_title_oldest_updated,
      sort_value_recently_created => sort_title_recently_created,
      sort_value_recently_signin  => sort_title_recently_signin,
      sort_value_recently_updated => sort_title_recently_updated,
      sort_value_popularity       => sort_title_popularity,
      sort_value_priority         => sort_title_priority,
      sort_value_upvotes          => sort_title_upvotes
    }
  end

  def projects_sort_options_hash
    options = {
      sort_value_latest_activity  => sort_title_latest_activity,
      sort_value_name             => sort_title_name,
      sort_value_oldest_activity  => sort_title_oldest_activity,
      sort_value_oldest_created   => sort_title_oldest_created,
      sort_value_recently_created => sort_title_recently_created
    }

    if current_controller?('admin/projects')
      options[sort_value_largest_repo] = sort_title_largest_repo
    end

    options
  end

  def groups_sort_options_hash
    {
      sort_value_name => sort_title_name,
      sort_value_name_desc => sort_title_name_desc,
      sort_value_recently_created => sort_title_recently_created,
      sort_value_oldest_created => sort_title_oldest_created,
      sort_value_recently_updated => sort_title_recently_updated,
      sort_value_oldest_updated => sort_title_oldest_updated
    }
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

  def sortable_item(item, path, sorted_by)
    link_to item, path, class: sorted_by == item ? 'is-active' : ''
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
    s_('SortOptions|Milestone')
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
end
