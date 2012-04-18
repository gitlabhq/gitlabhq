module SnippetsHelper
  def lifetime_select_options
    options = [
        [I18n.t('snippets.lifetime.forever'), nil],
        [I18n.t('snippets.lifetime.day'),   "#{Date.current + 1.day}"],
        [I18n.t('snippets.lifetime.week'),  "#{Date.current + 1.week}"],
        [I18n.t('snippets.lifetime.month'), "#{Date.current + 1.month}"]
    ]
    options_for_select(options)
  end
end
