# Code Quality **[STARTER]**

> [Introduced][ee-1984] in [GitLab Starter][ee] 9.3.

## Overview

If you are using [GitLab CI/CD][ci], you can analyze your source code quality
using GitLab Code Quality. Code Quality uses [Code Climate Engines][cc], which are
free and open source. Code Quality doesn’t require a Code Climate subscription.

Going a step further, GitLab Code Quality can show the Code Climate report right
in the merge request widget area:

![Code Quality Widget][quality-widget]

## Use cases

For instance, consider the following workflow:

1. Your backend team member starts a new implementation for making certain feature in your app faster
1. With Code Quality reports, they analyze how their implementation is impacting the code quality
1. The metrics show that their code degrade the quality in 10 points
1. You ask a co-worker to help them with this modification
1. They both work on the changes until Code Quality report displays no degradations, only improvements
1. You approve the merge request and authorize its deployment to staging
1. Once verified, their changes are deployed to production

## How it works

>**Note:**
In [GitLab Starter][ee] 10.0, another job name will
also be supported: `codequality`. This new job name will eventually replace
`codeclimate` which is scheduled to be removed in GitLab 11.0. You are advised
to update your current `.gitlab-ci.yml` configuration to reflect that change.

In order for the report to show in the merge request, you need to specify a
`codequality` job (exact name) that will analyze the code and upload the resulting
`codeclimate.json` as an artifact. GitLab will then check this file and show
the information inside the merge request.

>**Note:**
If the Code Climate report doesn't have anything to compare to, no information
will be displayed in the merge request area. That is the case when you add the
`codequality` job in your `.gitlab-ci.yml` for the very first time.
Consecutive merge requests will have something to compare to and the code quality
report will be shown properly.

For more information on how the `codequality` job should look like, check the
example on [analyzing a project's code quality with Code Climate CLI][cc-docs].

[ee-1984]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/1984
[ee]: https://about.gitlab.com/products/
[ci]: ../../../ci/README.md
[cc]: https://codeclimate.com
[cd]: https://hub.docker.com/r/codeclimate/codeclimate/
[quality-widget]: img/code_quality.gif
[cc-docs]: ../../../ci/examples/code_climate.md
