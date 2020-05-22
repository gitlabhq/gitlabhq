---
description: "Learn how long your open merge requests have spent in code review, and what distinguishes the longest-running." # Up to ~200 chars long. They will be displayed in Google Search snippets. It may help to write the page intro first, and then reuse it here.
stage: Manage
group: Analytics
To determine the technical writer assigned to the Stage/Group associated with this page, see:
  https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---


# Code Review Analytics **(STARTER)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/38062) in [GitLab Starter](https://about.gitlab.com/pricing/) 12.7.

Code Review Analytics makes it easy to view the longest-running reviews among open merge requests,
enabling you to take action on individual merge requests and reduce overall cycle time.

NOTE: **Note:**
Initially, no data will appear. Data is populated as users comment on open merge requests.

## Overview

Code Review Analytics displays a table of open merge requests that have at least one non-author comment. The review time is measured from the time the first non-author comment was submitted.
The code review period for a merge request is automatically identified as the time since the first non-author comment.

To access Code Review Analytics, from your project's menu, go to **{chart}** **Project Analytics > Code Review**.

![Code Review Analytics](img/code_review_analytics_v12_8.png "List of code reviews; oldest review first.")

- The table is sorted by review duration, helping you quickly find the longest-running reviews which may need intervention or to be broken down into smaller parts.
- You can filter the list of MRs by milestone and label.
- Columns to display the author, approvers, comment count, and line change (-/+) counts.

## Use cases

This feature is designed for [development team leaders](https://about.gitlab.com/handbook/marketing/product-marketing/roles-personas/#delaney-development-team-lead)
and others who want to understand broad code review dynamics, and identify patterns to help explain them.

You can use Code Review Analytics to expose your team's unique challenges with code review, and
identify improvements that might substantially accelerate your development cycle.

Code Review Analytics can be used when:

- Your team agrees that code review is moving too slow.
- The [Value Stream Analytics feature](value_stream_analytics.md) shows that reviews are your team's most time-consuming step.

You can use Code Review Analytics to see the types of work that are currently moving the slowest, and analyze the patterns
and trends between them. For example:

- Lots of comments or commits? Maybe the code is too complex.
- A particular author is involved? Maybe more training is required.
- Few comments and approvers? Maybe your team is understaffed.

## Permissions

- On [Starter or Bronze tier](https://about.gitlab.com/pricing/) and above.
- By users with Reporter access and above.
