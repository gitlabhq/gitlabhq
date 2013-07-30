module SnippetsHelper
  def lifetime_select_options
    options = [
        ['forever', nil],
        ['1 day',   "#{Date.current + 1.day}"],
        ['1 week',  "#{Date.current + 1.week}"],
        ['1 month', "#{Date.current + 1.month}"]
    ]
    options_for_select(options)
  end

  def visibility_select_options(opts={})
    options = [
      ['Private',       "private"],
      ['Gitlab Public', "gitlab_public"],
      ['World Public',  "world_public"]
    ]
    options_for_select(options, opts[:selected])
  end

  def reliable_snippet_path(snippet)
    if snippet.project_id?
      project_snippet_path(snippet.project, snippet)
    else
      snippet_path(snippet)
    end
  end
end
