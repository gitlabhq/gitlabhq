# rubocop:disable Naming/FileName -- Not applicable for ics file
# frozen_string_literal: true

cal = Icalendar::Calendar.new
cal.prodid = '-//GitLab//NONSGML GitLab//EN'
cal.x_wr_calname = 'GitLab Work Items'

work_items&.find_each do |work_item|
  cal.event do |event|
    event.dtstart = Icalendar::Values::Date.new(work_item.due_date)
    event.summary = "#{work_item.title} (in #{work_item.namespace.full_path})"
    event.description = "Find out more at #{project_work_item_url(work_item.project, work_item)}"
    event.url = project_work_item_url(work_item.project, work_item)
    event.transp = 'TRANSPARENT'
  end
end

cal.to_ical

# rubocop:enable Naming/FileName
