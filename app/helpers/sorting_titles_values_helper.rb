# frozen_string_literal: true

module SortingTitlesValuesHelper
  # Titles.
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

  def sort_title_merged_date
    s_('SortOptions|Merged date')
  end

  def sort_title_merged_recently
    s_('SortOptions|Merged recently')
  end

  def sort_title_merged_earlier
    s_('SortOptions|Merged earlier')
  end

  def sort_title_largest_group
    s_('SortOptions|Largest group')
  end

  def sort_title_largest_repo
    s_('SortOptions|Largest repository')
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

  # Values.
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

  def sort_value_merged_date
    'merged_at'
  end

  def sort_value_merged_recently
    'merged_at_desc'
  end

  def sort_value_merged_earlier
    'merged_at_asc'
  end

  def sort_value_largest_group
    'storage_size_desc'
  end

  def sort_value_largest_repo
    'storage_size_desc'
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
end

SortingHelper.include_mod_with('SortingTitlesValuesHelper')
