---
status: implemented
creation-date: "2023-10-18"
authors: [ "@DylanGriffith" ]
coach:
approvers: [ "@rymai", "@tigerwnz" ]
owning-stage: "~devops::tenant scale"
participating-stages: []
---

<!-- vale gitlab.FutureTense = NO -->

# GitLab Housekeeper - automating merge requests

## Summary

This blueprint documents the philosophy behind the
["GitLab Housekeeper" gem](https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-housekeeper)
which was introduced in
<https://gitlab.com/gitlab-org/gitlab/-/merge_requests/139492> and has already
been used to create many merge requests.

The tool should be used to save developers from mundane repetitive tasks that
can be automated. The tool is scoped to any task where a developer needs to
create a straightforward merge request and is known ahead of time.

This tool should be useful for at least the following kinds of mundane MRs
we create:

1. Remove a feature flag after X date
1. Remove an unused index where the unused index is identified by some
   automation
1. Remove an `ignore_column` after X date (part of renaming/removing columns
   multi-step procedure)
1. Populate sharding keys for organizations/cells on tables that are missing a
   sharding key

## Motivation

We've observed there are many cases where developers are doing a lot of
manual work for tasks that are entirely predictable and automatable. Often
these manual tasks are done after waiting some known period of time. As such we
usually create an issue and set the future milestone. Then in the future the
developer remembers to followup on that issue and opens an MR to make the
manual change.

The biggest examples we've seen lately are:

1. Feature flag removal: <https://gitlab.com/groups/gitlab-org/-/epics/5325>. We
   have many opportunities for automation with feature flags but this blueprint
   focuses on removing the feature flag after it's fully rolled out. A step
   that is often forgotten leading to growing technical debt.
1. Removing duplicated or unused indexes in Postgres:
   <https://gitlab.com/gitlab-org/gitlab/-/issues/385701>. For now we're
   developing automation that creates issues and assigns them to groups to
   follow up and manually open MRs to remove them. This blueprint would take it
   a step further and the automation would just create the MRs to remove them
   once we have identified them.
1. Removing out of date `ignore_column` references:
   <https://docs.gitlab.com/ee/development/database/avoiding_downtime_in_migrations.html#removing-the-ignore-rule-release-m2>
   . For now we leave a note in our code telling us the date it needs to be
   removed and often create an issue as a reminder. This blueprint proposes
   that automation just reads this note and opens the MR to remove it after the
   date.
1. Adding and backfilling sharding keys for organizations for Cells:
   <https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133796>. The cells
   architecture depends on all tables having a sharding key that is attributed
   to an organization. We will need to backfill this for ~300 tables. Much of
   this will be repetitive and mundane work that we can automate provided that
   groups just identify what the name of the sharding key should be and how we
   will backfill it. As such we can automate the creation of MRs that guess the
   sharding key and owning groups can check and correct those MRs. Then we can
   automate the MR creation for adding the columns and backfilling the data.
   Some kind of automation like this will be necessary to finish this work in a
   reasonable timeframe.

### Goals

1. Identify the common tasks that take development time and automate them.
1. Focus on MR creation rather than issue creation as MRs are the results we
   want and issues are a process for reminding us to get those results.
1. Improve developer job satisfaction by knowing that automation is doing the
   busy work while we get to do the challenging and creative work.
1. Developers should be encouraged to contribute to the automation framework
   when they see a pattern rather than documenting the manual work for future
   developers to do it again.
1. Automation MRs should be very easily identified and reviewed and merged much
   more quickly than other MRs. If our automation MRs cause too much effort for
   reviewers we maybe will outweigh the benefits. This might mean that some
   automations get disabled when they are just noisy.

## Solution

The
[GitLab Housekeeper gem](https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-housekeeper)
should be used to automate creation of mundane merge requests.

Using this tool reflects our
[bias for action](https://handbook.gitlab.com/handbook/values/#bias-for-action)
subvalue. As such, developers should preference contributing a new
[keep](https://gitlab.com/gitlab-org/gitlab/-/tree/master/keeps) over the following:

1. Documenting a process that involves creating several merge requests over a
   period of time
1. Setting up periodic reminders for developers (in Slack or issues) to create
   some merge request

The keeps may sometimes take more work to implement than documentation or
reminders so judgement should be used to assess the likely time savings from
using automation. The `gitlab-housekeeper` gem will evolve over time with many
utilities that make it simpler to contribute new keeps and it is expected that
over time the cost to implementing a keep should be small enough that we will
mostly prefer this whenever developers need to do a repeatable task more than a
few times.

## Design and implementation details

The key details for this architecture is:

1. The design of this tool is like a combination of `rubocop -a` and Renovate
   bot. It extends on `rubocop -a` to understand when things need to be removed
   after certain deadlines as well as creating a steady stream of manageable
   merge requests for the reviewer rather than leaving those decisions to the
   developer. Like the renovate bot it attempts to create MRs periodically and
   assign them to the right people to review.
1. The keeps live in the GitLab repo which means that there are no
   dependencies to update and the keeps can use code inside the
   GitLab codebase.
1. The script can be run locally by a developer or can be run periodically
   in some automated way.
1. The keeps are able to use any data sources (eg. local code, Prometheus,
   Postgres database archive, logs) needed to determine whether and how to make
   the change.
