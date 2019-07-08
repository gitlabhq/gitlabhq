---
type: reference, howto
---

# Browser Performance Testing **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/3507)
in [GitLab Premium](https://about.gitlab.com/pricing/) 10.3.

If your application offers a web interface and you are using
[GitLab CI/CD](../../../ci/README.md), you can quickly determine the performance
impact of pending code changes.

## Overview

GitLab uses [Sitespeed.io](https://www.sitespeed.io), a free and open source
tool for measuring the performance of web sites, and has built a simple
[Sitespeed plugin](https://gitlab.com/gitlab-org/gl-performance)
which outputs the results in a file called `performance.json`. This plugin
outputs the performance score for each page that is analyzed.

The [Sitespeed.io performance score](http://examples.sitespeed.io/6.0/2017-11-23-23-43-35/help.html)
is a composite value based on best practices, and we will be expanding support
for [additional metrics](https://gitlab.com/gitlab-org/gitlab-ee/issues/4370)
in a future release.

Going a step further, GitLab can show the Performance report right
in the merge request widget area:

## Use cases

For instance, consider the following workflow:

1. A member of the marketing team is attempting to track engagement by adding a new tool
1. With browser performance metrics, they see how their changes are impacting the usability of the page for end users
1. The metrics show that after their changes the performance score of the page has gone down
1. When looking at the detailed report, they see that the new Javascript library was included in `<head>` which affects loading page speed
1. They ask a front end developer to help them, who sets the library to load asynchronously
1. The frontend developer approves the merge request and authorizes its deployment to production

## How it works

First of all, you need to define a job in your `.gitlab-ci.yml` file that generates the
[Performance report artifact](../../../ci/yaml/README.md#artifactsreportsperformance-premium).
For more information on how the Performance job should look like, check the
example on [Testing Browser Performance](../../../ci/examples/browser_performance.md).

GitLab then checks this report, compares key performance metrics for each page
between the source and target branches, and shows the information right on the merge request.

>**Note:**
If the Performance report doesn't have anything to compare to, no information
will be displayed in the merge request area. That is the case when you add the
Performance job in your `.gitlab-ci.yml` for the very first time.
Consecutive merge requests will have something to compare to and the Performance
report will be shown properly.

![Performance Widget](img/browser_performance_testing.png)

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
