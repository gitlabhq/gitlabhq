cal = Icalendar::Calendar.new
cal.prodid = '-//GitLab//NONSGML GitLab//EN'
cal.x_wr_calname = 'GitLab Issues'

# rubocop: disable CodeReuse/ActiveRecord
@issues.preload(project: :namespace).each do |issue|
  cal.event do |event|
    event.dtstart     = Icalendar::Values::Date.new(issue.due_date)
    event.summary     = "#{issue.title} (in #{issue.project.full_path})"
    event.description = "Find out more at #{issue_url(issue)}"
    event.url         = issue_url(issue)
    event.transp      = 'TRANSPARENT'
  end
end
# rubocop: enable CodeReuse/ActiveRecord

cal.to_ical
