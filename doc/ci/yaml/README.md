# Configuration of your builds with .gitlab-ci.yml
From version 7.12, GitLab CI uses a [YAML](https://en.wikipedia.org/wiki/YAML) file (**.gitlab-ci.yml**) for the project configuration.
It is placed in the root of your repository and contains definitions of how your project should be built.

The YAML file defines a set of jobs with constraints stating when they should be run.
The jobs are defined as top-level elements with a name and always have to contain the `script` clause:

```yaml
job1:
  script: "execute-script-for-job1"

job2:
  script: "execute-script-for-job2"
```

The above example is the simplest possible CI configuration with two separate jobs,
where each of the jobs executes a different command.
Of course a command can execute code directly (`./configure;make;make install`) or run a script (`test.sh`) in the repository.

Jobs are used to create builds, which are then picked up by [runners](../runners/README.md) and executed within the environment of the runner.
What is important, is that each job is run independently from each other.

## .gitlab-ci.yml
The YAML syntax allows for using more complex job specifications than in the above example:

```yaml
image: ruby:2.1
services:
  - postgres

before_script:
  - bundle_install

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

There are a few `keywords` that can't be used as job names:

| keyword       | required | description |
|---------------|----------|-------------|
| image         | optional | Use docker image, covered in [Use Docker](../docker/README.md) |
| services      | optional | Use docker services, covered in [Use Docker](../docker/README.md) |
| stages        | optional | Define build stages |
| types         | optional | Alias for `stages` |
| before_script | optional | Define commands prepended for each job's script |
| variables     | optional | Define build variables |

### image and services
This allows to specify a custom Docker image and a list of services that can be used for time of the build.
The configuration of this feature is covered in separate document: [Use Docker](../docker/README.md).

### before_script
`before_script` is used to define the command that should be run before all builds, including deploy builds. This can be an array or a multiline string.

### stages
`stages` is used to define build stages that can be used by jobs.
The specification of `stages` allows for having flexible multi stage pipelines.

The ordering of elements in `stages` defines the ordering of builds' execution:

1. Builds of the same stage are run in parallel.
1. Builds of next stage are run after success.

Let's consider the following example, which defines 3 stages:
```
stages:
  - build
  - test
  - deploy
```

1. First all jobs of `build` are executed in parallel.
1. If all jobs of `build` succeeds, the `test` jobs are executed in parallel.
1. If all jobs of `test` succeeds, the `deploy` jobs are executed in parallel.
1. If all jobs of `deploy` succeeds, the commit is marked as `success`.
1. If any of the previous jobs fails, the commit is marked as `failed` and no jobs of further stage are executed.

There are also two edge cases worth mentioning:

1. If no `stages` is defined in `.gitlab-ci.yml`, then by default the `build`, `test` and `deploy` are allowed to be used as job's stage by default.
2. If a job doesn't specify `stage`, the job is assigned the `test` stage.

### types
Alias for [stages](#stages).

### variables
**This feature requires `gitlab-runner` with version equal or greater than 0.5.0.**

GitLab CI allows you to add to `.gitlab-ci.yml` variables that are set in build environment.
The variables are stored in repository and are meant to store non-sensitive project configuration, ie. RAILS_ENV or DATABASE_URL.

```yaml
variables:
  DATABASE_URL: "postgres://postgres@postgres/my_database"
```

These variables can be later used in all executed commands and scripts.

The YAML-defined variables are also set to all created service containers, thus allowing to fine tune them.

## Jobs
`.gitlab-ci.yml` allows you to specify an unlimited number of jobs.
Each job has to have a unique `job_name`, which is not one of the keywords mentioned above.
A job is defined by a list of parameters that define the build behaviour.

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

| keyword       | required | description |
|---------------|----------|-------------|
| script        | required | Defines a shell script which is executed by runner |
| stage         | optional (default: test) | Defines a build stage |
| type          | optional | Alias for `stage` |
| only          | optional | Defines a list of git refs for which build is created |
| except        | optional | Defines a list of git refs for which build is not created |
| tags          | optional | Defines a list of tags which are used to select runner |
| allow_failure | optional | Allow build to fail. Failed build doesn't contribute to commit status |
| when          | optional | Define when to run build. Can be `on_success`, `on_failure` or `always` |

### script
`script` is a shell script which is executed by runner. The shell script is prepended with `before_script`.

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

### stage
`stage` allows to group build into different stages. Builds of the same `stage` are executed in `parallel`.
For more info about the use of `stage` please check the [stages](#stages).

### only and except
This are two parameters that allow for setting a refs policy to limit when jobs are built:
1. `only` defines the names of branches and tags for which job will be built.
2. `except` defines the names of branches and tags for which the job wil **not** be built.

There are a few rules that apply to usage of refs policy:

1. `only` and `except` are exclusive. If both `only` and `except` are defined in job specification only `only` is taken into account.
1. `only` and `except` allow for using the regexp expressions.
1. `only` and `except` allow for using special keywords: `branches` and `tags`.
These names can be used for example to exclude all tags and all branches.

```yaml
job:
  only:
    - /^issue-.*$/ # use regexp
  except:
    - branches # use special keyword
```

### tags
`tags` is used to select specific runners from the list of all runners that are allowed to run this project.

During registration of a runner, you can specify the runner's tags, ie.: `ruby`, `postgres`, `development`.
`tags` allow you to run builds with runners that have the specified tags assigned:

```
job:
  tags:
    - ruby
    - postgres
```

The above specification will make sure that `job` is built by a runner that have `ruby` AND `postgres` tags defined.

### when
`when` is used to implement jobs that are run in case of failure or despite the failure.

`when` can be set to one of the following values:

1. `on_success` - execute build only when all builds from prior stages succeeded. This is the default.
1. `on_failure` - execute build only when at least one build from prior stages failed.
1. `always` - execute build despite the status of builds from prior stages.

```
stages:
- build
- cleanup_build
- test
- deploy
- cleanup

build:
  stage: build
  script:
  - make build

cleanup_build:
  stage: cleanup_build
  script:
  - cleanup build when failed
  when: on_failure

test:
  stage: test
  script:
  - make test

deploy:
  stage: deploy
  script:
  - make deploy

cleanup:
  stage: cleanup
  script:
  - cleanup after builds
  when: always
```

The above script will:
1. Execute `cleanup_build` only when the `build` failed,
2. Always execute `cleanup` as the last step in pipeline.

## Validate the .gitlab-ci.yml
Each instance of GitLab CI has an embedded debug tool called Lint.
You can find the link to the Lint in the project's settings page or use short url `/lint`.

## Skipping builds
There is one more way to skip all builds, if your commit message contains tag [ci skip]. In this case, commit will be created but builds will be skipped
