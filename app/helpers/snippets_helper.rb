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
end
