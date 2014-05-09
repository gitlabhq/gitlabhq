module LanguageStatsHelper
  def language_bg_color(language)
    Linguist::Language[language].color
  end

  def truncate_float(num, i = 1)
    factor = (i * 10).to_f
    (num * factor).floor / factor
  end

  def determine_bg_color(language_stats)
    language_bg_color(language_stats.keys.last)
  end

  def render_stats(language_stats)
    lang_stats = decorate_values(language_stats)
    stats = render partial: 'projects/tree/language_stats', locals: { stats: lang_stats }
    stats += render partial: 'projects/tree/language_graph', locals: { stats: lang_stats }
    stats.html_safe
  end

  private

  def decorate_values(items)
    items.each { |k, v| items[k] = truncate_float(v) }
    if !items.empty?
      total_except_last = items.values.take(items.values.length - 1).sum
      items[items.keys.last] = (100.0 - total_except_last).round(1)
    end
    items
  end
end
