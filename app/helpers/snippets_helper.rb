module SnippetsHelper
  def snippet_lifetime_select_options
    options = [
        ['forever', nil],
        ['1 day',   Date.strptime("#{Date.current.day}.#{Date.current.month}.#{Date.current.year}", "%d.%m.%Y") + 1.day],
        ['1 week',  Date.strptime("#{Date.current.day}.#{Date.current.month}.#{Date.current.year}", "%d.%m.%Y") + 1.week],
        ['1 month', Date.strptime("#{Date.current.day}.#{Date.current.month}.#{Date.current.year}", "%d.%m.%Y") + 1.month]
    ]
    options_for_select(options)
  end
end
