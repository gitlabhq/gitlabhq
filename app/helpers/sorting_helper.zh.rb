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
    }
  end

  def sort_title_oldest_updated
    '最先更新的在前'
  end

  def sort_title_recently_updated
    '最近更新的在前'
  end

  def sort_title_oldest_created
    '最先创建的在前'
  end

  def sort_title_recently_created
    '最新创建的在前'
  end

  def sort_title_milestone_soon
    '快到期的里程碑在前'
  end

  def sort_title_milestone_later
    '最晚到期的里程碑在前'
  end

  def sort_title_name
    '名称'
  end

  def sort_title_largest_repo
    '最大的仓库'
  end

  def sort_title_recently_signin
    '最近登录'
  end

  def sort_title_oldest_signin
    '最先登录的在前'
  end

  def sort_value_oldest_updated
    '更新时间升序'
  end

  def sort_value_recently_updated
    '更新时间降序'
  end

  def sort_value_oldest_created
    '创建时间升序'
  end

  def sort_value_recently_created
    '创建时间降序'
  end

  def sort_value_milestone_soon
    '里程碑到期时间升序'
  end

  def sort_value_milestone_later
    '里程碑到期时间降序'
  end

  def sort_value_name
    '名称升序'
  end

  def sort_value_largest_repo
    '仓库大小降序'
  end

  def sort_value_recently_signin
    '最近登录的在前'
  end

  def sort_value_oldest_signin
    '最先登录的在前'
  end
end
