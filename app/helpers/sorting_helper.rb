module SortingHelper
  def sort_options_hash
    {
      sort_value_name => sort_title_name,
      sort_value_recently_updated => sort_title_recently_updated,
      sort_value_oldest_updated => sort_title_oldest_updated,
      sort_value_recently_created => sort_title_recently_created,
      sort_value_oldest_created => sort_title_oldest_created,
      sort_value_milestone_soon => sort_title_milestone_soon,
      sort_value_milestone_later => sort_title_milestone_later,
      sort_value_largest_repo => sort_title_largest_repo,
      sort_value_recently_signin => sort_title_recently_signin,
      sort_value_oldest_signin => sort_title_oldest_signin,
      sort_value_downvotes => sort_title_downvotes,
      sort_value_upvotes => sort_title_upvotes
    }
  end

  def projects_sort_options_hash
    {
      sort_value_name => sort_title_name,
      sort_value_recently_updated => sort_title_recently_updated,
      sort_value_oldest_updated => sort_title_oldest_updated,
      sort_value_recently_created => sort_title_recently_created,
      sort_value_oldest_created => sort_title_oldest_created,
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

  def sort_title_largest_repo
    'Largest repository'
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

  def sort_value_name
    'name_asc'
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

  def sort_value_downvotes
    'downvotes_desc'
  end

  def sort_value_upvotes
    'upvotes_desc'
  end
end
