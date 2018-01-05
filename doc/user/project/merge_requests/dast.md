# Dynamic Application Security Testing (SAST)

> [Introduced][ee-4348] in [GitLab Enterprise Edition Ultimate][ee] 10.4.

## Overview

If you are using [GitLab CI/CD][ci], you can analyze your web application for known
vulnerabilities using Dynamic Application Security Testing (DAST), either by
including the CI job in your [existing `.gitlab-ci.yml` file][cc-docs] or
by implicitly using [Auto DAST](../../../topics/autodevops/index.md#auto-dast)
that is provided by [Auto DevOps](../../../topics/autodevops/index.md).

Going a step further, GitLab can show the vulnerability list right in the merge
request widget area:

![DAST Widget](img/dast-all.png)

By clicking on vlunerability you will be able to see details and url affected:

![DAST Widget Clicked](img/dast-single.png)

## Use cases

It helps you automatically find security vulnerabilities in your web applications
while you are developing and testing your applications

## How it works

In order for the report to show in the merge request, you need to specify a
`dast` job (exact name) that will analyze the running application and upload the resulting
`gl-dast-report.json` file as an artifact. GitLab will then check this file and
show the information inside the merge request.

This JSON file needs to be the only artifact file for the job. If you try
to also include other files, it will break the vulnerability display in the
merge request.

For more information on how the `dast` job should look like, check the
[example on analyzing a project's code for vulnerabilities][cc-docs].

[ee-4348]: https://gitlab.com/gitlab-org/gitlab-ee/issues/4348
[ee]: https://about.gitlab.com/gitlab-ee/
[ci]: ../../../ci/README.md
[cc-docs]: ../../../ci/examples/dast.md
