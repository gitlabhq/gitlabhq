module DiffHelper
  def safe_diff_files(project, diffs)
    if diff_hard_limit_enabled?
      diffs.first(Commit::DIFF_HARD_LIMIT_FILES)
    else
      diffs.first(Commit::DIFF_SAFE_FILES)
    end.map do |diff|
      Gitlab::Diff::File.new(project, @commit, diff)
    end
  end

  def show_diff_size_warninig?(project, diffs)
    safe_diff_files(project, diffs).size < diffs.size
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
