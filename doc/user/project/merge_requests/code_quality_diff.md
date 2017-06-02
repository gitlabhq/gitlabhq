# Code quality diff using Code Climate

> [Introduced][ee-1984] in [GitLab Enterprise Edition Starter][ee] 9.3.

If you are using [GitLab CI][ci], you can analyze your source code quality using
the [Code Climate][cc] analyzer [Docker image][cd]. Going a step further, GitLab
can show the Code Climate report right in the merge request widget area.

![Code Quality Widget][quality-widget]

In order for the report to show in the merge request, you need to specify a
`codeclimate` job (exact name) that will analyze the code and upload the resulting
`codeclimate.json` as an artifact. GitLab will then check this file and show
the information inside the merge request.

For more information on how the `codeclimate` job should look like, check the
example on [analyzing a project's code quality with Code Climate CLI][cc-docs].

[ee-1984]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/1984
[ee]: https://about.gitlab.com/gitlab-ee/
[ci]: ../../../ci/README.md
[cc]: https://codeclimate.com
[cd]: https://hub.docker.com/r/codeclimate/codeclimate/
[quality-widget]: img/code_quality.gif
[cc-docs]: ../../../ci/examples/code_climate.md
