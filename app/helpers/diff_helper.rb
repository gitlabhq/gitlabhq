module DiffHelper
  def safe_diff_files(diffs)
    if diff_hard_limit_enabled?
      diffs.first(Commit::DIFF_HARD_LIMIT_FILES)
    else
      diffs.first(Commit::DIFF_SAFE_FILES)
    end
  end

  def show_diff_size_warninig?(diffs)
    safe_diff_files(diffs).size < diffs.size
  end

  def diff_hard_limit_enabled?
    # Enabling hard limit allows user to see more diff information
    if params[:force_show_diff].present?
      true
    else
      false
    end
  end
end
