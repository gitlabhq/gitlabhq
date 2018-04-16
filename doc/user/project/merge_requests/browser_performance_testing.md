# Browser Performance Testing **[PREMIUM]**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/3507) in [GitLab Premium](https://about.gitlab.com/products/) 10.3.

## Overview

If your application offers a web interface and you are using
[GitLab CI/CD](../../../ci/README.md), you can quickly determine the performance
impact of pending code changes.

GitLab uses [Sitespeed.io](https://www.sitespeed.io), a free and open source
tool for measuring the performance of web sites, and has built a simple
[Sitespeed plugin](https://gitlab.com/gitlab-org/gl-performance)
which outputs the results in a file called `performance.json`. This plugin
outputs the performance score for each page that is analyzed.

The [Sitespeed.io performance score](https://examples.sitespeed.io/6.0/2017-11-23-23-43-35/help.html#performanceAdvice)
is a composite value based on best practices, and we will be expanding support
for [additional metrics](https://gitlab.com/gitlab-org/gitlab-ee/issues/4370)
in a future release.

## Use cases

For instance, consider the following workflow:

1. A member of the marketing team is attempting to track engagement by adding a new tool
1. With browser performance metrics, they see how their changes are impacting the usability of the page for end users
1. The metrics show that after their changes the performance score of the page has gone down
1. When looking at the detailed report, they see that the new Javascript library was included in `<head>` which affects loading page speed
1. They ask a front end developer to help them, who sets the library to load asynchronously
1. The frontend developer approves the merge request and authorizes its deployment to production

## How it works

First of all, you need to define a job named `performance` in your `.gitlab-ci.yml`
file. [Check how the `performance` job should look like](../../../ci/examples/browser_performance.md).

GitLab runs the [Sitespeed.io container](https://hub.docker.com/r/sitespeedio/sitespeed.io/)
and compares key performance metrics for each page between the source and target
branches of a merge request. The difference for each page is then shown right on
the merge request.

In order for the report to show in the merge request, there are two
prerequisites:

- the specified job **must** be named `performance`
- the resulting report **must** be named `performance.json` and uploaded as an
  artifact

If the performance report doesn't have anything to compare to, no information
will be displayed in the merge request area. That is the case when you add the
`performance` job in your `.gitlab-ci.yml` for the very first time.
Consecutive merge requests will have something to compare to and the performance
report will be shown properly.

![Performance Widget](img/browser_performance_testing.png)
