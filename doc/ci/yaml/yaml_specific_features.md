---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# YAML-specific features

In your `.gitlab-ci.yml` file, you can use YAML-specific features like anchors (`&`), aliases (`*`),
and map merging (`<<`). Use these features to reduce the complexity
of the code in the `.gitlab-ci.yml` file.

Read more about the various [YAML features](https://learnxinyminutes.com/docs/yaml/).

In most cases, the [`extends` keyword](index.md#extends) is more user friendly and you should
use it when possible.

You can use YAML anchors to merge YAML arrays.

## Anchors

YAML has a feature called 'anchors' that you can use to duplicate
content across your document.

Use anchors to duplicate or inherit properties. Use anchors with [hidden jobs](../jobs/index.md#hide-jobs)
to provide templates for your jobs. When there are duplicate keys, GitLab
performs a reverse deep merge based on the keys.

You can't use YAML anchors across multiple files when using the [`include`](index.md#include)
keyword. Anchors are only valid in the file they were defined in. To reuse configuration
from different YAML files, use [`!reference` tags](#reference-tags) or the
[`extends` keyword](index.md#extends).

The following example uses anchors and map merging. It creates two jobs,
`test1` and `test2`, that inherit the `.job_template` configuration, each
with their own custom `script` defined:

```yaml
.job_template: &job_configuration  # Hidden yaml configuration that defines an anchor named 'job_configuration'
  image: ruby:2.6
  services:
    - postgres
    - redis

test1:
  <<: *job_configuration           # Merge the contents of the 'job_configuration' alias
  script:
    - test1 project

test2:
  <<: *job_configuration           # Merge the contents of the 'job_configuration' alias
  script:
    - test2 project
```

`&` sets up the name of the anchor (`job_configuration`), `<<` means "merge the
given hash into the current one," and `*` includes the named anchor
(`job_configuration` again). The expanded version of this example is:

```yaml
.job_template:
  image: ruby:2.6
  services:
    - postgres
    - redis

test1:
  image: ruby:2.6
  services:
    - postgres
    - redis
  script:
    - test1 project

test2:
  image: ruby:2.6
  services:
    - postgres
    - redis
  script:
    - test2 project
```

You can use anchors to define two sets of services. For example, `test:postgres`
and `test:mysql` share the `script` defined in `.job_template`, but use different
`services`, defined in `.postgres_services` and `.mysql_services`:

```yaml
.job_template: &job_configuration
  script:
    - test project
  tags:
    - dev

.postgres_services:
  services: &postgres_configuration
    - postgres
    - ruby

.mysql_services:
  services: &mysql_configuration
    - mysql
    - ruby

test:postgres:
  <<: *job_configuration
  services: *postgres_configuration
  tags:
    - postgres

test:mysql:
  <<: *job_configuration
  services: *mysql_configuration
```

The expanded version is:

```yaml
.job_template:
  script:
    - test project
  tags:
    - dev

.postgres_services:
  services:
    - postgres
    - ruby

.mysql_services:
  services:
    - mysql
    - ruby

test:postgres:
  script:
    - test project
  services:
    - postgres
    - ruby
  tags:
    - postgres

test:mysql:
  script:
    - test project
  services:
    - mysql
    - ruby
  tags:
    - dev
```

You can see that the hidden jobs are conveniently used as templates, and
`tags: [postgres]` overwrites `tags: [dev]`.

### YAML anchors for scripts

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/23005) in GitLab 12.5.

You can use [YAML anchors](#anchors) with [script](index.md#script), [`before_script`](index.md#before_script),
and [`after_script`](index.md#after_script) to use predefined commands in multiple jobs:

```yaml
.some-script-before: &some-script-before
  - echo "Execute this script first"

.some-script: &some-script
  - echo "Execute this script second"
  - echo "Execute this script too"

.some-script-after: &some-script-after
  - echo "Execute this script last"

job1:
  before_script:
    - *some-script-before
  script:
    - *some-script
    - echo "Execute something, for this job only"
  after_script:
    - *some-script-after

job2:
  script:
    - *some-script-before
    - *some-script
    - echo "Execute something else, for this job only"
    - *some-script-after
```

### YAML anchors for variables

Use [YAML anchors](#anchors) with `variables` to repeat assignment
of variables across multiple jobs. You can also use YAML anchors when a job
requires a specific `variables` block that would otherwise override the global variables.

The following example shows how override the `GIT_STRATEGY` variable without affecting
the use of the `SAMPLE_VARIABLE` variable:

```yaml
# global variables
variables: &global-variables
  SAMPLE_VARIABLE: sample_variable_value
  ANOTHER_SAMPLE_VARIABLE: another_sample_variable_value

# a job that must set the GIT_STRATEGY variable, yet depend on global variables
job_no_git_strategy:
  stage: cleanup
  variables:
    <<: *global-variables
    GIT_STRATEGY: none
  script: echo $SAMPLE_VARIABLE
```

## `!reference` tags

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/266173) in GitLab 13.9.
> - `rules` keyword support [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/322992) in GitLab 14.3.

Use the `!reference` custom YAML tag to select keyword configuration from other job
sections and reuse it in the current section. Unlike [YAML anchors](#anchors), you can
use `!reference` tags to reuse configuration from [included](index.md#include) configuration
files as well.

In the following example, a `script` and an `after_script` from two different locations are
reused in the `test` job:

- `setup.yml`:

  ```yaml
  .setup:
    script:
      - echo creating environment
  ```

- `.gitlab-ci.yml`:

  ```yaml
  include:
    - local: setup.yml

  .teardown:
    after_script:
      - echo deleting environment

  test:
    script:
      - !reference [.setup, script]
      - echo running my own command
    after_script:
      - !reference [.teardown, after_script]
  ```

In the following example, `test-vars-1` reuses all the variables in `.vars`, while `test-vars-2`
selects a specific variable and reuses it as a new `MY_VAR` variable.

```yaml
.vars:
  variables:
    URL: "http://my-url.internal"
    IMPORTANT_VAR: "the details"

test-vars-1:
  variables: !reference [.vars, variables]
  script:
    - printenv

test-vars-2:
  variables:
    MY_VAR: !reference [.vars, variables, IMPORTANT_VAR]
  script:
    - printenv
```

You can't reuse a section that already includes a `!reference` tag. Only one level
of nesting is supported.
