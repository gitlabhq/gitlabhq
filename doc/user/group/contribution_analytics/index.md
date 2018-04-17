# Contribution Analytics **[STARTER]**

>**Note:**
Introduced in [GitLab Starter][ee] 8.3.

Track your team members' activity across your organization.

## Overview

With contribution analytics you can have an overview for the activity of
issues, merge requests and push events of your organization and its members.

The analytics page is located at **Group > Contribution Analytics**
under the URL `/groups/<groupname>/analytics`.

## Use-cases

- Analyze your team's contributions along a period of time and offer a bonus
  for the top contributors
- If you are unhappy with a particular team member, you can use the analytics
  as argument for demanding efficiency from this person

## Using Contribution Analytics

There are three main bar graphs that are deducted from the number of
contributions per group member. These contributions include push events, merge
requests and closed issues. Hovering on each bar you can see the number of
events for a specific member.

![Contribution analytics bar graphs](img/group_stats_graph.png)

## Changing the period time

There are three periods you can choose from: 'Last week', 'Last month' and
'Last three months'. The default is 'Last week'.

You can choose which period to display by using the dropdown calendar menu in
the upper right corner.

![Contribution analytics choose period](img/group_stats_cal.png)

## Sorting by different factors

Apart from the bar graphs you can also see the contributions per group member
which are depicted in a table that can be sorted by:

* Member name
* Number of pushed events
* Number of opened issues
* Number of closed issues
* Number of opened MRs
* Number of accepted MRs
* Number of total contributions

![Contribution analytics contributions table](img/group_stats_table.png)

[ee]: https://about.gitlab.com/products/
