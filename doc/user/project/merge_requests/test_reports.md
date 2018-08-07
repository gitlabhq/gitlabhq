# Verify your code with Test reports

> Introduced in GitLab 11.2
> This feature requires GitLab Runner version 11.2 or above

## Overview

Test is an important step in DevOps toolchain. Your customers are lokking forward to seeing new features in your product,
however, nobody wants to experience broken features or regressions.

That's why GitLab CI comes into play. Every single time when developers push a new change,
CI pipeline runs and verify their code doesn't break anything.
If it's goog, pipelines are colored green. If not, pipelines are colored red.

It's a pretty simple indicator until now, but as of GitLab 11.2, we started stepping further.
You can see test reports about what/why new code broke features.

![Test Reports Widget][test-reports-widget]

## Use cases

For instance, consider the following workflow:

1. Your `master` branch is rock solid. Your project is configured with GitLab CI and pipelines indicates there are nothing broken.
1. You submitted a merge request. It seems there are something wrong in the new code, but all you can see is that CI pipelines inidicate red icon.
   To investigate more, you have to go through [job logs](link). Sometimes it contains thousands of lines. It's painful to figure out the cause.
1. You'll tweak gitlab-ci.yml to [collect test reports](link) from each job. Now you can see which test is broken at a glance in merge request widget.
1. Your development flow becoms much easier and efficient.

## How it works

Test reports in merge request is a compared results between base and head pipeline. Base pipeline is a target branch of merge requests, which typically `master` branch is specified.
Head pipeline is a source branch of merge requests, which means the latest pipieline in each merge request.

When you visit a merge request, GitLab starts comapring head and base pipeline's test reports, and yield three types of results

1. Newly failed tests: Test cases which passed on base branch and failed on head branch
1. Existing failures:  Test cases which failed on base branch and failed on head branch
1. Resolved failures:  Test cases which failed on base branch and passed on head branch
1. Sumamry of the above

You can also see System Output and Stack Trace by clicking each rows.

[test-reports-widget]: img/test_reports.gif
