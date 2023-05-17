# frozen_string_literal: true

module BlameHelper
  BODY_FONT_SIZE = "0.875rem"
  COMMIT_LINE_HEIGHT = 3 # 150% * 2 lines of text
  COMMIT_PADDING = "10px" # 5px from both top and bottom
  COMMIT_BLOCK_HEIGHT_EXP = "(#{BODY_FONT_SIZE} * #{COMMIT_LINE_HEIGHT}) + #{COMMIT_PADDING}"
  CODE_LINE_HEIGHT = 1.1875
  CODE_PADDING = "20px" # 10px from both top and bottom

  def age_map_duration(blame_groups, project)
    now = Time.zone.now
    start_date = blame_groups.map { |blame_group| blame_group[:commit].committed_date }
      .append(project.created_at).min

    {
      now: now,
      started_days_ago: (now - start_date).to_i / 1.day
    }
  end

  def age_map_class(commit_date, duration)
    if duration[:started_days_ago] == 0
      "blame-commit-age-0"
    else
      commit_date_days_ago = (duration[:now] - commit_date).to_i / 1.day
      # Numbers 0 to 10 come from this calculation, but only commits on the oldest
      # day get number 10 (all other numbers can be multiple days), so the range
      # is normalized to 0-9
      age_group = [(10 * commit_date_days_ago) / duration[:started_days_ago], 9].min
      "blame-commit-age-#{age_group}"
    end
  end

  def intrinsic_row_css(line_count)
    # using rems here because the size of the row depends on the text size
    # which can be customized via user agent styles and browser preferences
    total_line_height_exp = "#{line_count * CODE_LINE_HEIGHT}rem + #{CODE_PADDING}"
    row_height_exp = line_count == 1 ? COMMIT_BLOCK_HEIGHT_EXP : total_line_height_exp
    "contain-intrinsic-size: 1px calc(#{row_height_exp})"
  end

  def blame_pages_streaming_url(id, project)
    namespace_project_blame_page_url(namespace_id: project.namespace, project_id: project, id: id, streaming: true)
  end

  def entire_blame_path(id, project)
    namespace_project_blame_streaming_path(namespace_id: project.namespace, project_id: project, id: id)
  end
end
