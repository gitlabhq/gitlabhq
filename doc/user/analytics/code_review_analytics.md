---
description: "Learn how long your open merge requests have spent in code review, and what distinguishes the longest-running." # Up to ~200 chars long. They will be displayed in Google Search snippets. It may help to write the page intro first, and then reuse it here.
---

# Code Review Analytics **(STARTER)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/38062) in [GitLab Starter](https://about.gitlab.com/pricing/) 12.7.

Code Review Analytics can be used to answer questions like:

- How long do open merge requests spend in code review?
- What distinguishes your longest-running code reviews?

NOTE: **Note:**
Initially no data will appear. Data is populated as users comment on open merge requests.

## Overview

Code Review Analytics displays a table of open merge requests, which are considered to be in code review.
Code review starts when a merge request receives its first comment from someone other than the author.

The Code Review Analytics table:

- Is sorted by review time, so the longest reviews appear at the top.
- Has columns to display the author, approvers, comment count, and line -/+ counts.

This feature is designed for [development team leaders](https://about.gitlab.com/handbook/marketing/product-marketing/roles-personas/#delaney-development-team-lead)
and others who want to understand broad code review dynamics, and identify patterns to help explain them.

You can use Code Review Analytics to expose your team's unique challenges with code review, and
identify improvements that might substantially accelerate your development cycle.

## Use cases

Code Review Analytics can be used when:

- Your team agrees that code review is moving too slow.
- The [Cycle Analytics feature](cycle_analytics.md) shows that reviews are your team's most time-consuming step.

You can use Code Review Analytics to see what is currently moving slowest, and analyze the patterns
and trends between them. For example:

- Lots of comments or commits? Maybe the code is too complex.
- A particular author is involved? Maybe more training is required.
- Few comments and approvers? Maybe your team is understaffed.

## Permissions

- On [Starter or Bronze tier](https://about.gitlab.com/pricing/) and above.
- By users with Reporter access and above.

## Disable with feature flag

Code Review Analytics is [currently enabled by a feature flag](https://gitlab.com/gitlab-org/gitlab/issues/194165)
that defaults to ON, meaning the feature is available. If you experience performance problems or
otherwise wish to disable the feature, a GitLab administrator can execute a command in a Rails console:

```ruby
Feature.disable(:code_review_analytics)
```
