# Code quality diff

> [Introduced][ee-1984] in GitLab Enterprise Edition 9.3.

If you are using GitLab CI you can analyze your source code quality using
Code Climate analyzer docker image. Then GitLab will show you how merge request
changes source code quality right inside merge request widget.

![Code Quality Widget][quality-widget]

## Enabling feature

Feature can be enabled by following next steps: 

1. [Analyze project code quality with Code Climate CLI ][cc-docs] 
2. Start a new merge request from branch that already has codeclimate job succeed
3. Wait till merge request codeclimate job succeed
  
[ee-1984]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/1984
[quality-widget]: img/code_quality.gif
[cc-docs]: https://docs.gitlab.com/ce/ci/examples/code_climate.html#analyze-project-code-quality-with-code-climate-cli 
