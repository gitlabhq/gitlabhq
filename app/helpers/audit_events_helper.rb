module AuditEventsHelper
  def human_text(details)
    details.map{ |key, value| select_keys(key, value) }.join(" ").humanize
  end

  def select_keys(key, value)
    if key.match(/^(author|target)_.*/)
      ""
    else
      "#{key.to_s} <strong>#{value}</strong>"
    end
  end
end
