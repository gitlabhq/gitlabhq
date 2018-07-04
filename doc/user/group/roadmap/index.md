# Roadmap **[ULTIMATE]**

> Introduced in [GitLab Ultimate][ee] 10.5.

An Epic within a group containing **Planned start date** and/or **Planned finish date**
can be visualized in a form of a timeline (e.g. a Gantt chart). The Epics Roadmap page
shows such a visualization for all the epics which are under a group and/or its subgroups.

![roadmap view](img/roadmap_view.png)

## Timeline duration

Starting with [GitLab Ultimate][ee] 11.0, Roadmap supports three different date ranges; Quarters, Months (Default) and Weeks.

### Quarters

![roadmap date range in quarters](img/roadmap_timeline_quarters.png)

In _Quarters_ preset, roadmap shows epics which have planned start or finish dates _falling within_ or
_going through_ **past quarter**, **current quarter** and **next 4 quarters**, where _today_
is shown by the vertical red line in the timeline. The sub-headers underneath the quarter name on
the timeline header represent the month of the quarter.

### Months

![roadmap date range in months](img/roadmap_timeline_months.png)

In _Months_ preset, roadmap shows epics which have planned start or finish dates _falling within_ or
_going through_ **past month**, **current month** and **next 5 months**, where _today_
is shown by the vertical red line in the timeline. The sub-headers underneath the month name on
the timeline header represent the date on starting day (Sunday) of the week. This preset is
selected by default.

### Weeks

![roadmap date range in weeks](img/roadmap_timeline_weeks.png)

In _Weeks_ preset, roadmap shows epics which have planned start or finish dates _falling within_ or
_going through_ **past week**, **current week** and **next 4 weeks**, where _today_
is shown by the vertical red line in the timeline. The sub-headers underneath the week name on
the timeline header represent the days of the week.

## Timeline bar for an epic

The timeline bar indicates the approximate position of an epic based on its planned start
and finish date. If an epic doesn't have a planned finish date, the timeline bar fades
away towards the future. Similarly, if an epic doesn't have a planned start date, the
timeline bar becomes more visible as it approaches the epic's planned finish date on the
timeline.

[ee]: https://about.gitlab.com/pricing
