---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# GitLab CI/CD include examples **(FREE)**

In addition to the [`includes` examples](index.md#include) listed in the
[GitLab CI YAML reference](index.md), this page lists more variations of `include`
usage.

## Single string or array of multiple values

You can include your extra YAML file(s) either as a single string or
an array of multiple values. The following examples are all valid.

Single string with the `include:local` method implied:

```yaml
include: '/templates/.after-script-template.yml'
```

Array with `include` method implied:

```yaml
include:
  - 'https://gitlab.com/awesome-project/raw/main/.before-script-template.yml'
  - '/templates/.after-script-template.yml'
```

Single string with `include` method specified explicitly:

```yaml
include:
  remote: 'https://gitlab.com/awesome-project/raw/main/.before-script-template.yml'
```

Array with `include:remote` being the single item:

```yaml
include:
  - remote: 'https://gitlab.com/awesome-project/raw/main/.before-script-template.yml'
```

Array with multiple `include` methods specified explicitly:

```yaml
include:
  - remote: 'https://gitlab.com/awesome-project/raw/main/.before-script-template.yml'
  - local: '/templates/.after-script-template.yml'
  - template: Auto-DevOps.gitlab-ci.yml
```

Array mixed syntax:

```yaml
include:
  - 'https://gitlab.com/awesome-project/raw/main/.before-script-template.yml'
  - '/templates/.after-script-template.yml'
  - template: Auto-DevOps.gitlab-ci.yml
  - project: 'my-group/my-project'
    ref: main
    file: '/templates/.gitlab-ci-template.yml'
```

## Re-using a `before_script` template

In the following example, the content of `.before-script-template.yml` is
automatically fetched and evaluated along with the content of `.gitlab-ci.yml`.

Content of `https://gitlab.com/awesome-project/raw/main/.before-script-template.yml`:

```yaml
default:
  before_script:
    - apt-get update -qq && apt-get install -y -qq sqlite3 libsqlite3-dev nodejs
    - gem install bundler --no-document
    - bundle install --jobs $(nproc)  "${FLAGS[@]}"
```

Content of `.gitlab-ci.yml`:

```yaml
include: 'https://gitlab.com/awesome-project/raw/main/.before-script-template.yml'

rspec:
  script:
    - bundle exec rspec
```

## Overriding external template values

The following example shows specific YAML-defined variables and details of the
`production` job from an include file being customized in `.gitlab-ci.yml`.

Content of `https://company.com/autodevops-template.yml`:

```yaml
variables:
  POSTGRES_USER: user
  POSTGRES_PASSWORD: testing_password
  POSTGRES_DB: $CI_ENVIRONMENT_SLUG

production:
  stage: production
  script:
    - install_dependencies
    - deploy
  environment:
    name: production
    url: https://$CI_PROJECT_PATH_SLUG.$KUBE_INGRESS_BASE_DOMAIN
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

Content of `.gitlab-ci.yml`:

```yaml
include: 'https://company.com/autodevops-template.yml'

image: alpine:latest

variables:
  POSTGRES_USER: root
  POSTGRES_PASSWORD: secure_password

stages:
  - build
  - test
  - production

production:
  environment:
    url: https://domain.com
```

In this case, the variables `POSTGRES_USER` and `POSTGRES_PASSWORD` along
with the environment URL of the `production` job defined in
`autodevops-template.yml` have been overridden by new values defined in
`.gitlab-ci.yml`.

The merging lets you extend and override dictionary mappings, but
you cannot add or modify items to an included array. For example, to add
an additional item to the production job script, you must repeat the
existing script items:

Content of `https://company.com/autodevops-template.yml`:

```yaml
production:
  stage: production
  script:
    - install_dependencies
    - deploy
```

Content of `.gitlab-ci.yml`:

```yaml
include: 'https://company.com/autodevops-template.yml'

stages:
  - production

production:
  script:
    - install_dependencies
    - deploy
    - notify_owner
```

In this case, if `install_dependencies` and `deploy` were not repeated in
`.gitlab-ci.yml`, they would not be part of the script for the `production`
job in the combined CI configuration.

## Using nested includes

The examples below show how includes can be nested from different sources
using a combination of different methods.

In this example, `.gitlab-ci.yml` includes local the file `/.gitlab-ci/another-config.yml`:

```yaml
include:
  - local: /.gitlab-ci/another-config.yml
```

The `/.gitlab-ci/another-config.yml` includes a template and the `/templates/docker-workflow.yml` file
from another project:

```yaml
include:
  - template: Bash.gitlab-ci.yml
  - project: group/my-project
    file: /templates/docker-workflow.yml
```

The `/templates/docker-workflow.yml` present in `group/my-project` includes two local files
of the `group/my-project`:

```yaml
include:
  - local: /templates/docker-build.yml
  - local: /templates/docker-testing.yml
```

Our `/templates/docker-build.yml` present in `group/my-project` adds a `docker-build` job:

```yaml
docker-build:
  script: docker build -t my-image .
```

Our second `/templates/docker-test.yml` present in `group/my-project` adds a `docker-test` job:

```yaml
docker-test:
  script: docker run my-image /run/tests.sh
```
