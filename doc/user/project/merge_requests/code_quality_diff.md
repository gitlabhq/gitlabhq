# Code Quality

> [Introduced][ee-1984] in [GitLab Enterprise Edition Starter][ee] 9.3.

## Overview

If you are using [GitLab CI][ci], you can analyze your source code quality using
the [Code Climate][cc] analyzer [Docker image][cd]. Going a step further, GitLab
can show the Code Climate report right in the merge request widget area.

![Code Quality Widget][quality-widget]

## Use cases

For instance, consider the following workflow:

1. Your backend team member starts a new implementation for making certain feature in your app faster
1. With Code Quality reports, they analize how their implementation is impacting the code quality
1. The metrics show that their code degrade the quality in 10 points
1. You ask a co-worker to help them with this modification
1. They both work on the changes until Code Quality report displays no degradations, only improvements
1. You approve the merge request and authorize its deployment to staging
1. Once verified, their changes are deployed to production

## How it works

In order for the report to show in the merge request, you need to specify a
`codeclimate` job (exact name) that will analyze the code and upload the resulting
`codeclimate.json` as an artifact. GitLab will then check this file and show
the information inside the merge request.

`codeclimate.json` needs to be the only artifact file for the job. If you try
to also include other files, like Code Climate's HTML report, it will break the
Code Climate display in the merge request.

If the Code Climate report doesn't have anything to compare to, no information
will be displayed in the merge request area. That is the case when you add the
`codeclimate` job in your `.gitlab-ci.yml` for the very first time.
Consecutive merge requests will have something to compare to and the code quality
report will be shown properly.

For more information on how the `codeclimate` job should look like, check the
example on [analyzing a project's code quality with Code Climate CLI][cc-docs].

[ee-1984]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/1984
[ee]: https://about.gitlab.com/gitlab-ee/
[ci]: ../../../ci/README.md
[cc]: https://codeclimate.com
[cd]: https://hub.docker.com/r/codeclimate/codeclimate/
[quality-widget]: img/code_quality.gif
[cc-docs]: ../../../ci/examples/code_climate.md
