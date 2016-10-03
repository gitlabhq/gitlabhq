# Configuration of your builds with .gitlab-ci.yml

This document describes the usage of `.gitlab-ci.yml`, the file that is used by
GitLab Runner to manage your project's builds.

If you want a quick introduction to GitLab CI, follow our
[quick start guide](../quick_start/README.md).

## .gitlab-ci.yml

From version 7.12, GitLab CI uses a [YAML](https://en.wikipedia.org/wiki/YAML)
file (`.gitlab-ci.yml`) for the project configuration. It is placed in the root
of your repository and contains definitions of how your project should be built.

The YAML file defines a set of jobs with constraints stating when they should
be run. The jobs are defined as top-level elements with a name and always have
to contain at least the `script` clause:

```yaml
job1:
  script: "execute-script-for-job1"

job2:
  script: "execute-script-for-job2"
```

The above example is the simplest possible CI configuration with two separate
jobs, where each of the jobs executes a different command.

Of course a command can execute code directly (`./configure;make;make install`)
or run a script (`test.sh`) in the repository.

Jobs are used to create builds, which are then picked up by
[Runners](../runners/README.md) and executed within the environment of the
Runner. What is important, is that each job is run independently from each
other.

The YAML syntax allows for using more complex job specifications than in the
above example:

```yaml
image: ruby:2.1
services:
  - postgres

before_script:
  - bundle install

after_script:
  - rm secrets

stages:
  - build
  - test
  - deploy

job1:
  stage: build
  script:
    - execute-script-for-job1
  only:
    - master
  tags:
    - docker
```

There are a few reserved `keywords` that **cannot** be used as job names:

| Keyword       | Required | Description |
|---------------|----------|-------------|
| image         | no | Use docker image, covered in [Use Docker](../docker/README.md) |
| services      | no | Use docker services, covered in [Use Docker](../docker/README.md) |
| stages        | no | Define build stages |
| types         | no | Alias for `stages` |
| before_script | no | Define commands that run before each job's script |
| after_script  | no | Define commands that run after each job's script |
| variables     | no | Define build variables |
| cache         | no | Define list of files that should be cached between subsequent runs |

### image and services

This allows to specify a custom Docker image and a list of services that can be
used for time of the build. The configuration of this feature is covered in
[a separate document](../docker/README.md).

### before_script

`before_script` is used to define the command that should be run before all
builds, including deploy builds. This can be an array or a multi-line string.

### after_script

> Introduced in GitLab 8.7 and requires Gitlab Runner v1.2

`after_script` is used to define the command that will be run after for all
builds. This has to be an array or a multi-line string.

### stages

`stages` is used to define build stages that can be used by jobs.
The specification of `stages` allows for having flexible multi stage pipelines.

The ordering of elements in `stages` defines the ordering of builds' execution:

1. Builds of the same stage are run in parallel.
1. Builds of the next stage are run after the jobs from the previous stage
   complete successfully.

Let's consider the following example, which defines 3 stages:

```yaml
stages:
  - build
  - test
  - deploy
```

1. First all jobs of `build` are executed in parallel.
1. If all jobs of `build` succeed, the `test` jobs are executed in parallel.
1. If all jobs of `test` succeed, the `deploy` jobs are executed in parallel.
1. If all jobs of `deploy` succeed, the commit is marked as `success`.
1. If any of the previous jobs fails, the commit is marked as `failed` and no
   jobs of further stage are executed.

There are also two edge cases worth mentioning:

1. If no `stages` are defined in `.gitlab-ci.yml`, then by default the `build`,
   `test` and `deploy` are allowed to be used as job's stage by default.
2. If a job doesn't specify a `stage`, the job is assigned the `test` stage.

### types

Alias for [stages](#stages).

### variables

> Introduced in GitLab Runner v0.5.0.

GitLab CI allows you to add variables to `.gitlab-ci.yml` that are set in the
build environment. The variables are stored in the Git repository and are meant
to store non-sensitive project configuration, for example:

```yaml
variables:
  DATABASE_URL: "postgres://postgres@postgres/my_database"
```

These variables can be later used in all executed commands and scripts.

The YAML-defined variables are also set to all created service containers,
thus allowing to fine tune them.

Variables can be also defined on [job level](#job-variables).

[Learn more about variables.](../variables/README.md)

### cache

> Introduced in GitLab Runner v0.7.0.

`cache` is used to specify a list of files and directories which should be
cached between builds.

**By default the caching is enabled per-job and per-branch.**

If `cache` is defined outside the scope of the jobs, it means it is set
globally and all jobs will use its definition.

Cache all files in `binaries` and `.config`:

```yaml
rspec:
  script: test
  cache:
    paths:
    - binaries/
    - .config
```

Cache all Git untracked files:

```yaml
rspec:
  script: test
  cache:
    untracked: true
```

Cache all Git untracked files and files in `binaries`:

```yaml
rspec:
  script: test
  cache:
    untracked: true
    paths:
    - binaries/
```

Locally defined cache overwrites globally defined options. This will cache only
`binaries/`:

```yaml
cache:
  paths:
  - my/files

rspec:
  script: test
  cache:
    paths:
    - binaries/
```

The cache is provided on a best-effort basis, so don't expect that the cache
will be always present. For implementation details, please check GitLab Runner.

#### cache:key

> Introduced in GitLab Runner v1.0.0.

The `key` directive allows you to define the affinity of caching
between jobs, allowing to have a single cache for all jobs,
cache per-job, cache per-branch or any other way you deem proper.

This allows you to fine tune caching, allowing you to cache data between
different jobs or even different branches.

The `cache:key` variable can use any of the [predefined variables](../variables/README.md).

---

**Example configurations**

To enable per-job caching:

```yaml
cache:
  key: "$CI_BUILD_NAME"
  untracked: true
```

To enable per-branch caching:

```yaml
cache:
  key: "$CI_BUILD_REF_NAME"
  untracked: true
```

To enable per-job and per-branch caching:

```yaml
cache:
  key: "$CI_BUILD_NAME/$CI_BUILD_REF_NAME"
  untracked: true
```

To enable per-branch and per-stage caching:

```yaml
cache:
  key: "$CI_BUILD_STAGE/$CI_BUILD_REF_NAME"
  untracked: true
```

If you use **Windows Batch** to run your shell scripts you need to replace
`$` with `%`:

```yaml
cache:
  key: "%CI_BUILD_STAGE%/%CI_BUILD_REF_NAME%"
  untracked: true
```

## Jobs

`.gitlab-ci.yml` allows you to specify an unlimited number of jobs. Each job
must have a unique name, which is not one of the Keywords mentioned above.
A job is defined by a list of parameters that define the build behavior.

```yaml
job_name:
  script:
    - rake spec
    - coverage
  stage: test
  only:
    - master
  except:
    - develop
  tags:
    - ruby
    - postgres
  allow_failure: true
```

| Keyword       | Required | Description |
|---------------|----------|-------------|
| script        | yes | Defines a shell script which is executed by Runner |
| image         | no | Use docker image, covered in [Using Docker Images](../docker/using_docker_images.md#define-image-and-services-from-gitlab-ciyml) |
| services      | no | Use docker services, covered in [Using Docker Images](../docker/using_docker_images.md#define-image-and-services-from-gitlab-ciyml) |
| stage         | no | Defines a build stage (default: `test`) |
| type          | no | Alias for `stage` |
| variables     | no | Define build variables on a job level |
| only          | no | Defines a list of git refs for which build is created |
| except        | no | Defines a list of git refs for which build is not created |
| tags          | no | Defines a list of tags which are used to select Runner |
| allow_failure | no | Allow build to fail. Failed build doesn't contribute to commit status |
| when          | no | Define when to run build. Can be `on_success`, `on_failure`, `always` or `manual` |
| dependencies  | no | Define other builds that a build depends on so that you can pass artifacts between them|
| artifacts     | no | Define list of build artifacts |
| cache         | no | Define list of files that should be cached between subsequent runs |
| before_script | no | Override a set of commands that are executed before build |
| after_script  | no | Override a set of commands that are executed after build |
| environment   | no | Defines a name of environment to which deployment is done by this build |

### script

`script` is a shell script which is executed by the Runner. For example:

```yaml
job:
  script: "bundle exec rspec"
```

This parameter can also contain several commands using an array:

```yaml
job:
  script:
    - uname -a
    - bundle exec rspec
```

Sometimes, `script` commands will need to be wrapped in single or double quotes. For example, commands that contain a colon (`:`) need to be wrapped in quotes so that the YAML parser knows to interpret the whole thing as a string rather than a "key: value" pair. Be careful when using special characters (`:`, `{`, `}`, `[`, `]`, `,`, `&`, `*`, `#`, `?`, `|`, `-`, `<`, `>`, `=`, `!`, `%`, `@`, `` ` ``).

### stage

`stage` allows to group build into different stages. Builds of the same `stage`
are executed in `parallel`. For more info about the use of `stage` please check
[stages](#stages).

### only and except

`only` and `except` are two parameters that set a refs policy to limit when
jobs are built:

1. `only` defines the names of branches and tags for which the job will be
    built.
2. `except` defines the names of branches and tags for which the job will
    **not** be built.

There are a few rules that apply to the usage of refs policy:

* `only` and `except` are inclusive. If both `only` and `except` are defined
   in a job specification, the ref is filtered by `only` and `except`.
* `only` and `except` allow the use of regular expressions.
* `only` and `except` allow the use of special keywords: `branches`, `tags`, and `triggers`.
* `only` and `except` allow to specify a repository path to filter jobs for
   forks.

In the example below, `job` will run only for refs that start with `issue-`,
whereas all branches will be skipped.

```yaml
job:
  # use regexp
  only:
    - /^issue-.*$/
  # use special keyword
  except:
    - branches
```

In this example, `job` will run only for refs that are tagged, or if a build is explicitly requested
via an API trigger.

```yaml
job:
  # use special keywords
  only:
    - tags
    - triggers
```

The repository path can be used to have jobs executed only for the parent
repository and not forks:

```yaml
job:
  only:
    - branches@gitlab-org/gitlab-ce
  except:
    - master@gitlab-org/gitlab-ce
```

The above example will run `job` for all branches on `gitlab-org/gitlab-ce`,
except master.

### job variables

It is possible to define build variables using a `variables` keyword on a job
level. It works basically the same way as its global-level equivalent but
allows you to define job-specific build variables.

When the `variables` keyword is used on a job level, it overrides global YAML
build variables and predefined variables.

Build variables priority is defined in
[variables documentation](../variables/README.md).

### tags

`tags` is used to select specific Runners from the list of all Runners that are
allowed to run this project.

During the registration of a Runner, you can specify the Runner's tags, for
example `ruby`, `postgres`, `development`.

`tags` allow you to run builds with Runners that have the specified tags
assigned to them:

```yaml
job:
  tags:
    - ruby
    - postgres
```

The specification above, will make sure that `job` is built by a Runner that
has both `ruby` AND `postgres` tags defined.

### allow_failure

`allow_failure` is used when you want to allow a build to fail without impacting
the rest of the CI suite. Failed builds don't contribute to the commit status.

When enabled and the build fails, the pipeline will be successful/green for all
intents and purposes, but a "CI build passed with warnings" message  will be
displayed on the merge request or commit or build page. This is to be used by
builds that are allowed to fail, but where failure indicates some other (manual)
steps should be taken elsewhere.

In the example below, `job1` and `job2` will run in parallel, but if `job1`
fails, it will not stop the next stage from running, since it's marked with
`allow_failure: true`:

```yaml
job1:
  stage: test
  script:
  - execute_script_that_will_fail
  allow_failure: true

job2:
  stage: test
  script:
  - execute_script_that_will_succeed

job3:
  stage: deploy
  script:
  - deploy_to_staging
```

### when

`when` is used to implement jobs that are run in case of failure or despite the
failure.

`when` can be set to one of the following values:

1. `on_success` - execute build only when all builds from prior stages
    succeed. This is the default.
1. `on_failure` - execute build only when at least one build from prior stages
    fails.
1. `always` - execute build regardless of the status of builds from prior stages.
1. `manual` - execute build manually (added in GitLab 8.10). Read about
    [manual actions](#manual-actions) below.

For example:

```yaml
stages:
- build
- cleanup_build
- test
- deploy
- cleanup

build_job:
  stage: build
  script:
  - make build

cleanup_build_job:
  stage: cleanup_build
  script:
  - cleanup build when failed
  when: on_failure

test_job:
  stage: test
  script:
  - make test

deploy_job:
  stage: deploy
  script:
  - make deploy
  when: manual

cleanup_job:
  stage: cleanup
  script:
  - cleanup after builds
  when: always
```

The above script will:

1. Execute `cleanup_build_job` only when `build_job` fails.
2. Always execute `cleanup_job` as the last step in pipeline regardless of
   success or failure.
3. Allow you to manually execute `deploy_job` from GitLab's UI.

#### Manual actions

> Introduced in GitLab 8.10.

Manual actions are a special type of job that are not executed automatically;
they need to be explicitly started by a user. Manual actions can be started
from pipeline, build, environment, and deployment views. You can execute the
same manual action multiple times.

An example usage of manual actions is deployment to production.

### environment

> Introduced in GitLab 8.9.

`environment` is used to define that a job deploys to a specific [environment].
This allows easy tracking of all deployments to your environments straight from
GitLab.

If `environment` is specified and no environment under that name exists, a new
one will be created automatically.

The `environment` name must contain only letters, digits, '-', '_', '/', '$', '{', '}' and spaces. Common
names are `qa`, `staging`, and `production`, but you can use whatever name works
with your workflow.

---

**Example configurations**

```
deploy to production:
  stage: deploy
  script: git push production HEAD:master
  environment: production
```

The `deploy to production` job will be marked as doing deployment to
`production` environment.

#### dynamic environments

> [Introduced][ce-6323] in GitLab 8.12 and GitLab Runner 1.6.

`environment` can also represent a configuration hash with `name` and `url`.
These parameters can use any of the defined CI [variables](#variables)
(including predefined, secure variables and `.gitlab-ci.yml` variables).

The common use case is to create dynamic environments for branches and use them
as review apps.

---

**Example configurations**

```
deploy as review app:
  stage: deploy
  script: ...
  environment:
    name: review-apps/$CI_BUILD_REF_NAME
    url: https://$CI_BUILD_REF_NAME.review.example.com/
```

The `deploy as review app` job will be marked as deployment to dynamically
create the `review-apps/branch-name` environment.

This environment should be accessible under `https://branch-name.review.example.com/`.

### artifacts

>**Notes:**
>
> - Introduced in GitLab Runner v0.7.0 for non-Windows platforms.
> - Windows support was added in GitLab Runner v.1.0.0.
> - Currently not all executors are supported.
> - Build artifacts are only collected for successful builds by default.

`artifacts` is used to specify a list of files and directories which should be
attached to the build after success. To pass artifacts between different builds,
see [dependencies](#dependencies).

Below are some examples.

Send all files in `binaries` and `.config`:

```yaml
artifacts:
  paths:
  - binaries/
  - .config
```

Send all Git untracked files:

```yaml
artifacts:
  untracked: true
```

Send all Git untracked files and files in `binaries`:

```yaml
artifacts:
  untracked: true
  paths:
  - binaries/
```

You may want to create artifacts only for tagged releases to avoid filling the
build server storage with temporary build artifacts.

Create artifacts only for tags (`default-job` will not create artifacts):

```yaml
default-job:
  script:
    - mvn test -U
  except:
    - tags

release-job:
  script:
    - mvn package -U
  artifacts:
    paths:
    - target/*.war
  only:
    - tags
```

The artifacts will be sent to GitLab after a successful build and will
be available for download in the GitLab UI.

#### artifacts:name

> Introduced in GitLab 8.6 and GitLab Runner v1.1.0.

The `name` directive allows you to define the name of the created artifacts
archive. That way, you can have a unique name for every archive which could be
useful when you'd like to download the archive from GitLab. The `artifacts:name`
variable can make use of any of the [predefined variables](../variables/README.md).
The default name is `artifacts`, which becomes `artifacts.zip` when downloaded.

---

**Example configurations**

To create an archive with a name of the current build:

```yaml
job:
  artifacts:
    name: "$CI_BUILD_NAME"
```

To create an archive with a name of the current branch or tag including only
the files that are untracked by Git:

```yaml
job:
   artifacts:
     name: "$CI_BUILD_REF_NAME"
     untracked: true
```

To create an archive with a name of the current build and the current branch or
tag including only the files that are untracked by Git:

```yaml
job:
  artifacts:
    name: "${CI_BUILD_NAME}_${CI_BUILD_REF_NAME}"
    untracked: true
```

To create an archive with a name of the current [stage](#stages) and branch name:

```yaml
job:
  artifacts:
    name: "${CI_BUILD_STAGE}_${CI_BUILD_REF_NAME}"
    untracked: true
```

---

If you use **Windows Batch** to run your shell scripts you need to replace
`$` with `%`:

```yaml
job:
  artifacts:
    name: "%CI_BUILD_STAGE%_%CI_BUILD_REF_NAME%"
    untracked: true
```

#### artifacts:when

> Introduced in GitLab 8.9 and GitLab Runner v1.3.0.

`artifacts:when` is used to upload artifacts on build failure or despite the
failure.

`artifacts:when` can be set to one of the following values:

1. `on_success` - upload artifacts only when the build succeeds. This is the default.
1. `on_failure` - upload artifacts only when the build fails.
1. `always` - upload artifacts regardless of the build status.

---

**Example configurations**

To upload artifacts only when build fails.

```yaml
job:
  artifacts:
    when: on_failure
```

#### artifacts:expire_in

> Introduced in GitLab 8.9 and GitLab Runner v1.3.0.

`artifacts:expire_in` is used to delete uploaded artifacts after the specified
time. By default, artifacts are stored on GitLab forever. `expire_in` allows you
to specify how long artifacts should live before they expire, counting from the
time they are uploaded and stored on GitLab.

You can use the **Keep** button on the build page to override expiration and
keep artifacts forever.

After expiry, artifacts are actually deleted hourly by default (via a cron job),
but they are not accessible after expiry.

The value of `expire_in` is an elapsed time. Examples of parseable values:
- '3 mins 4 sec'
- '2 hrs 20 min'
- '2h20min'
- '6 mos 1 day'
- '47 yrs 6 mos and 4d'
- '3 weeks and 2 days'

---

**Example configurations**

To expire artifacts 1 week after being uploaded:

```yaml
job:
  artifacts:
    expire_in: 1 week
```

### dependencies

> Introduced in GitLab 8.6 and GitLab Runner v1.1.1.

This feature should be used in conjunction with [`artifacts`](#artifacts) and
allows you to define the artifacts to pass between different builds.

Note that `artifacts` from all previous [stages](#stages) are passed by default.

To use this feature, define `dependencies` in context of the job and pass
a list of all previous builds from which the artifacts should be downloaded.
You can only define builds from stages that are executed before the current one.
An error will be shown if you define builds from the current stage or next ones.
Defining an empty array will skip downloading any artifacts for that job.

---

In the following example, we define two jobs with artifacts, `build:osx` and
`build:linux`. When the `test:osx` is executed, the artifacts from `build:osx`
will be downloaded and extracted in the context of the build. The same happens
for `test:linux` and artifacts from `build:linux`.

The job `deploy` will download artifacts from all previous builds because of
the [stage](#stages) precedence:

```yaml
build:osx:
  stage: build
  script: make build:osx
  artifacts:
    paths:
    - binaries/

build:linux:
  stage: build
  script: make build:linux
  artifacts:
    paths:
    - binaries/

test:osx:
  stage: test
  script: make test:osx
  dependencies:
  - build:osx

test:linux:
  stage: test
  script: make test:linux
  dependencies:
  - build:linux

deploy:
  stage: deploy
  script: make deploy
```

### before_script and after_script

It's possible to overwrite globally defined `before_script` and `after_script`:

```yaml
before_script:
- global before script

job:
  before_script:
  - execute this instead of global before script
  script:
  - my command
  after_script:
  - execute this after my script
```

## Git Strategy

> Introduced in GitLab 8.9 as an experimental feature. May change in future
  releases or be removed completely.

You can set the `GIT_STRATEGY` used for getting recent application code. `clone`
is slower, but makes sure you have a clean directory before every build. `fetch`
is faster. `GIT_STRATEGY` can be specified in the global `variables` section or
in the `variables` section for individual jobs. If it's not specified, then the
default from project settings will be used.

```
variables:
  GIT_STRATEGY: clone
```

or

```
variables:
  GIT_STRATEGY: fetch
```

## Shallow cloning

> Introduced in GitLab 8.9 as an experimental feature. May change in future
releases or be removed completely.

You can specify the depth of fetching and cloning using `GIT_DEPTH`. This allows
shallow cloning of the repository which can significantly speed up cloning for
repositories with a large number of commits or old, large binaries. The value is
passed to `git fetch` and `git clone`.

>**Note:**
If you use a depth of 1 and have a queue of builds or retry
builds, jobs may fail.

Since Git fetching and cloning is based on a ref, such as a branch name, runners
can't clone a specific commit SHA. If there are multiple builds in the queue, or
you are retrying an old build, the commit to be tested needs to be within the
git history that is cloned. Setting too small a value for `GIT_DEPTH` can make
it impossible to run these old commits. You will see `unresolved reference` in
build logs. You should then reconsider changing `GIT_DEPTH` to a higher value.

Builds that rely on `git describe` may not work correctly when `GIT_DEPTH` is
set since only part of the git history is present.

To fetch or clone only the last 3 commits:
```
variables:
  GIT_DEPTH: "3"
```

## Hidden keys

> Introduced in GitLab 8.6 and GitLab Runner v1.1.1.

Keys that start with a dot (`.`) will be not processed by GitLab CI. You can
use this feature to ignore jobs, or use the
[special YAML features](#special-yaml-features) and transform the hidden keys
into templates.

In the following example, `.key_name` will be ignored:

```yaml
.key_name:
  script:
    - rake spec
```

Hidden keys can be hashes like normal CI jobs, but you are also allowed to use
different types of structures to leverage special YAML features.

## Special YAML features

It's possible to use special YAML features like anchors (`&`), aliases (`*`)
and map merging (`<<`), which will allow you to greatly reduce the complexity
of `.gitlab-ci.yml`.

Read more about the various [YAML features](https://learnxinyminutes.com/docs/yaml/).

### Anchors

> Introduced in GitLab 8.6 and GitLab Runner v1.1.1.

YAML also has a handy feature called 'anchors', which let you easily duplicate
content across your document. Anchors can be used to duplicate/inherit
properties, and is a perfect example to be used with [hidden keys](#hidden-keys)
to provide templates for your jobs.

The following example uses anchors and map merging. It will create two jobs,
`test1` and `test2`, that will inherit the parameters of `.job_template`, each
having their own custom `script` defined:

```yaml
.job_template: &job_definition  # Hidden key that defines an anchor named 'job_definition'
  image: ruby:2.1
  services:
    - postgres
    - redis

test1:
  <<: *job_definition           # Merge the contents of the 'job_definition' alias
  script:
    - test1 project

test2:
  <<: *job_definition           # Merge the contents of the 'job_definition' alias
  script:
    - test2 project
```

`&` sets up the name of the anchor (`job_definition`), `<<` means "merge the
given hash into the current one", and `*` includes the named anchor
(`job_definition` again). The expanded version looks like this:

```yaml
.job_template:
  image: ruby:2.1
  services:
    - postgres
    - redis

test1:
  image: ruby:2.1
  services:
    - postgres
    - redis
  script:
    - test1 project

test2:
  image: ruby:2.1
  services:
    - postgres
    - redis
  script:
    - test2 project
```

Let's see another one example. This time we will use anchors to define two sets
of services. This will create two jobs, `test:postgres` and `test:mysql`, that
will share the `script` directive defined in `.job_template`, and the `services`
directive defined in `.postgres_services` and `.mysql_services` respectively:

```yaml
.job_template: &job_definition
  script:
    - test project

.postgres_services:
  services: &postgres_definition
    - postgres
    - ruby

.mysql_services:
  services: &mysql_definition
    - mysql
    - ruby

test:postgres:
  <<: *job_definition
  services: *postgres_definition

test:mysql:
  <<: *job_definition
  services: *mysql_definition
```

The expanded version looks like this:

```yaml
.job_template:
  script:
    - test project

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

test:mysql:
  script:
    - test project
  services:
    - mysql
    - ruby
```

You can see that the hidden keys are conveniently used as templates.

## Triggers

Triggers can be used to force a rebuild of a specific branch, tag or commit,
with an API call.

[Read more in the triggers documentation.](../triggers/README.md)

## Validate the .gitlab-ci.yml

Each instance of GitLab CI has an embedded debug tool called Lint.
You can find the link under `/ci/lint` of your gitlab instance.

## Skipping builds

If your commit message contains `[ci skip]` or `[skip ci]`, using any
capitalization, the commit will be created but the builds will be skipped.

## Examples

Visit the [examples README][examples] to see a list of examples using GitLab
CI with various languages.

[examples]: ../examples/README.md
[ce-6323]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/6323
[environment]: ../environments.md
