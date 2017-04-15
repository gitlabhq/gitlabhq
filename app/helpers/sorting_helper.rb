module SortingHelper
  def sort_options_hash
    {
      sort_value_name => sort_title_name,
      sort_value_name_desc => sort_title_name_desc,
      sort_value_recently_updated => sort_title_recently_updated,
      sort_value_oldest_updated => sort_title_oldest_updated,
      sort_value_recently_created => sort_title_recently_created,
      sort_value_oldest_created => sort_title_oldest_created,
      sort_value_milestone_soon => sort_title_milestone_soon,
      sort_value_milestone_later => sort_title_milestone_later,
      sort_value_due_date_soon => sort_title_due_date_soon,
      sort_value_due_date_later => sort_title_due_date_later,
      sort_value_largest_repo => sort_title_largest_repo,
      sort_value_largest_group => sort_title_largest_group,
      sort_value_recently_signin => sort_title_recently_signin,
      sort_value_oldest_signin => sort_title_oldest_signin,
      sort_value_downvotes => sort_title_downvotes,
      sort_value_upvotes => sort_title_upvotes,
      sort_value_priority => sort_title_priority,
      sort_value_label_priority => sort_title_label_priority
    }
  end

  def projects_sort_options_hash
    options = {
      sort_value_name => sort_title_name,
      sort_value_latest_activity => sort_title_latest_activity,
      sort_value_oldest_activity => sort_title_oldest_activity,
      sort_value_recently_created => sort_title_recently_created,
      sort_value_oldest_created => sort_title_oldest_created
    }

    if current_controller?('admin/projects')
      options[sort_value_largest_repo] = sort_title_largest_repo
    end

    options
  end

  def member_sort_options_hash
    {
      sort_value_access_level_asc => sort_title_access_level_asc,
      sort_value_access_level_desc => sort_title_access_level_desc,
      sort_value_last_joined => sort_title_last_joined,
      sort_value_oldest_joined => sort_title_oldest_joined,
      sort_value_name => sort_title_name_asc,
      sort_value_name_desc => sort_title_name_desc,
      sort_value_recently_signin => sort_title_recently_signin,
      sort_value_oldest_signin => sort_title_oldest_signin
    }
  end

  def milestone_sort_options_hash
    {
      sort_value_name => sort_title_name_asc,
      sort_value_name_desc => sort_title_name_desc,
      sort_value_due_date_soon => sort_title_due_date_soon,
      sort_value_due_date_later => sort_title_due_date_later,
      sort_value_start_date_soon => sort_title_start_date_soon,
      sort_value_start_date_later => sort_title_start_date_later,
    }
  end

  def sort_title_priority
    'Priority'
  end

  def sort_title_label_priority
    'Label priority'
  end

  def sort_title_oldest_updated
    'Oldest updated'
  end

  def sort_title_recently_updated
    'Last updated'
  end

  def sort_title_oldest_activity
    'Oldest updated'
  end

  def sort_title_latest_activity
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

  def sort_title_due_date_soon
    'Due soon'
  end

  def sort_title_due_date_later
    'Due later'
  end

  def sort_title_start_date_soon
    'Start soon'
  end

  def sort_title_start_date_later
    'Start later'
  end

  def sort_title_name
    'Name'
  end

  def sort_title_largest_repo
    'Largest repository'
  end

  def sort_title_largest_group
    'Largest group'
  end

  def sort_title_recently_signin
    'Recent sign in'
  end

  def sort_title_oldest_signin
    'Oldest sign in'
  end

  def sort_title_downvotes
    'Least popular'
  end

  def sort_title_upvotes
    'Most popular'
  end

  def sort_title_last_joined
    'Last joined'
  end

  def sort_title_oldest_joined
    'Oldest joined'
  end

  def sort_title_access_level_asc
    'Access level, ascending'
  end

  def sort_title_access_level_desc
    'Access level, descending'
  end

  def sort_title_name_asc
    'Name, ascending'
  end

  def sort_title_name_desc
    'Name, descending'
  end

  def sort_value_last_joined
    'last_joined'
  end

  def sort_value_oldest_joined
    'oldest_joined'
  end

  def sort_value_access_level_asc
    'access_level_asc'
  end

  def sort_value_access_level_desc
    'access_level_desc'
  end

  def sort_value_name_desc
    'name_desc'
  end

  def sort_value_priority
    'priority'
  end

  def sort_value_label_priority
    'label_priority'
  end

  def sort_value_oldest_updated
    'updated_asc'
  end

  def sort_value_recently_updated
    'updated_desc'
  end

  def sort_value_oldest_activity
    'latest_activity_asc'
  end

  def sort_value_latest_activity
    'latest_activity_desc'
  end

  def sort_value_oldest_created
    'created_asc'
  end

  def sort_value_recently_created
    'created_desc'
  end

  def sort_value_milestone_soon
    'milestone_due_asc'
  end

  def sort_value_milestone_later
    'milestone_due_desc'
  end

  def sort_value_due_date_soon
    'due_date_asc'
  end

  def sort_value_due_date_later
    'due_date_desc'
  end

  def sort_value_start_date_soon
    'start_date_asc'
  end

  def sort_value_start_date_later
    'start_date_desc'
  end

  def sort_value_name
    'name_asc'
  end

  def sort_value_largest_repo
    'storage_size_desc'
  end

  def sort_value_largest_group
    'storage_size_desc'
  end

  def sort_value_recently_signin
    'recent_sign_in'
  end

  def sort_value_oldest_signin
    'oldest_sign_in'
  end

  def sort_value_downvotes
    'downvotes_desc'
  end

  def sort_value_upvotes
    'upvotes_desc'
  end
end
