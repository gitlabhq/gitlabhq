---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI/CD steps
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated
**Status:** Experiment

Steps are reusable units of a job that when composed together replace the `script` used in a GitLab CI/CD job.
While you are not required to use steps, the reusability, composability, testability, and independence
of steps make it easier to understand and maintain CI/CD pipeline.

To get started, you can try the [Set up steps tutorial](../../tutorials/setup_steps/_index.md).
To start creating your own steps, see [Creating your own step](#create-your-own-step). To understand how pipelines can benefit
from using both CI/CD Components and CI/CD Steps, see [Combine CI/CD Components and CI/CD Steps](#combine-cicd-components-and-cicd-steps).

This experimental feature is still in active development and might have breaking
changes at any time. Review the [changelog](https://gitlab.com/gitlab-org/step-runner/-/blob/main/CHANGELOG.md)
for full details on any breaking changes.

## Step workflow

A step either runs a sequence of steps or executes a command. Each step specifies inputs received and outputs returned, has
access to CI/CD job variables, environment variables, and resources provided by the execution environment such as the file
system and networking. Steps are hosted locally on the file system, in GitLab.com repositories, or in any other Git source.

Additionally, steps:

- Run in a Docker container created by the Steps team, you can review the [`Dockerfile`](https://gitlab.com/gitlab-org/step-runner/-/blob/main/Dockerfile).
  Follow [epic 15073](https://gitlab.com/groups/gitlab-org/-/epics/15073) to track
  when steps will run inside the environment defined by the CI/CD job.
- Are specific to Linux. Follow [epic 15074](https://gitlab.com/groups/gitlab-org/-/epics/15074)
  to track when steps supports multiple operating systems.

For example, this job uses the [`run`](../yaml/_index.md#run) CI/CD keyword to run a step:

```yaml
job:
  variables:
    CI_SAY_HI_TO: "Sally"
  run:
    - name: say_hi
      step: gitlab.com/gitlab-org/ci-cd/runner-tools/echo-step@v1.0.0
      inputs:
        message: "hello, ${{job.CI_SAY_HI_TO}}"
```

When this job runs, the message `hello, Sally` is printed to job log.
The definition of the echo step is:

```yaml
spec:
  inputs:
    message:
      type: string
---
exec:
  command:
    - bash
    - -c
    - echo '${{inputs.message}}'
```

## Use CI/CD Steps

Configure a GitLab CI/CD job to use CI Steps with the `run` keyword. You cannot use `before_script`,
`after_script`, or `script` in a job when you are running CI/CD Steps.

The `run` keyword accepts a list of steps to run. Steps are run one at a time in the order they are defined in the list.
Each list item has a `name` and either `step`, `script`, or `action`.

Name must consist only of alphanumeric characters and underscores, and must not start with a number.

### Run a step

Run a step by providing the [step location](#step-location) using the `step` keyword.

Inputs and environment variables can be passed to the step, and these can contain expressions that interpolate values.
Steps run in the directory defined by the `CI_BUILDS_DIR` [predefined variable](../variables/predefined_variables.md).

For example, the echo step loaded from the Git repository `gitlab.com/components/echo`
receives the environment variable `USER: Fred` and the input `message: hello Sally`:

```yaml
job:
  variables:
    CI_SAY_HI_TO: "Sally"
  run:
    - name: say_hi
      step: gitlab.com/components/echo@v1.0.0
      env:
        USER: "Fred"
      inputs:
        message: "hello ${{job.CI_SAY_HI_TO}}"
```

### Run a script

Run a script in a shell with the `script` keyword. Environment variables passed to scripts
using `env` are set in the shell. Script steps run in the directory defined by the `CI_BUILDS_DIR`
[predefined variable](../variables/predefined_variables.md).

For example, the following script prints the GitLab user to the job log:

```yaml
my-job:
  run:
    - name: say_hi
      script: echo hello ${{job.GITLAB_USER_LOGIN}}
```

Script steps always use the `bash` shell. Follow [issue 109](https://gitlab.com/gitlab-org/step-runner/-/issues/109)
to track when shell fallback is supported.

### Run a GitHub action

Run GitHub actions with the `action` keyword. Inputs and environment variables are passed directly to the
action, and action outputs are returned as step outputs. Action steps run in the directory
defined by the `CI_PROJECT_DIR` [predefined variable](../variables/predefined_variables.md).

Running actions requires the `dind` service. For more information, see
[Use Docker to build Docker images](../docker/using_docker_build.md).

For example, the following step uses `action` to make `yq` available:

```yaml
my-job:
  run:
    - name: say_hi_again
      action: mikefarah/yq@master
      inputs:
        cmd: echo ["hi ${{job.GITLAB_USER_LOGIN}} again!"] | yq .[0]
```

#### Known issues

Actions running in GitLab do not support uploading artifacts directly.
Artifacts must be written to the file system and cache instead, and selected with the
existing [`artifacts` keyword](../yaml/_index.md#artifacts) and [`cache` keyword](../yaml/_index.md#cache).

### Step location

Steps are loaded from a relative path on the file system, GitLab.com repositories,
or any other Git source.

#### Load a step from the file system

Load a step from the file system using a relative path that starts with a full-stop `.`.
The folder referenced by the path must contain a `step.yml` step definition file.
Path separators must always use forward-slashes `/`, regardless of operating system.

For example:

```yaml
- name: my-step
  step: ./path/to/my-step
```

#### Load a step from a Git repository

Load a step from a Git repository by supplying the URL and revision (commit, branch, or tag) of the repository.
You can also specify the relative directory and filename of the step within the `steps` folder of the repository.
If the URL is specified without a directory, then `step.yml` is loaded from the `steps` folder.

For example:

- Specify the step with a branch:

  ```yaml
  job:
    run:
      - name: specifying_a_branch
        step: gitlab.com/components/echo@main
  ```

- Specify the step with a tag:

  ```yaml
  job:
    run:
      - name: specifying_a_tag
        step: gitlab.com/components/echo@v1.0.0
  ```

- Specify the step with a directory, filename, and Git commit in a repository:

  ```yaml
  job:
    run:
      - name: specifying_a_directory_file_and_commit_within_the_repository
        step: gitlab.com/components/echo/-/reverse/my-step.yml@3c63f399ace12061db4b8b9a29f522f41a3d7f25
  ```

To specify a folder or file outside the `steps` folder, use the expanded `step` syntax:

- Specify a directory and filename relative to the repository root.

  ```yaml
  job:
    run:
      - name: specifying_a_directory_outside_steps
        step:
          git:
            url: gitlab.com/components/echo
            rev: main
            dir: my-steps/sub-directory  # optional, defaults to the repository root
            file: my-step.yml            # optional, defaults to `step.yml`
  ```

Steps can't reference Git repositories using annotated tags. Follow [issue 123](https://gitlab.com/gitlab-org/step-runner/-/issues/123)
to track when annotated tags are supported.

### Expressions

Expressions are a mini-language enclosed in double curly-braces `${{ }}`. Expressions are evaluated
just prior to step execution in the job environment and can be used in:

- Input values
- Environment variable values
- Step location URL
- The executable command
- The executable work directory
- Outputs in a sequence of steps
- The `script` step
- The `action` step

Expressions can reference the following variables:

| Variable                    | Example                                                       | Description |
|:----------------------------|:--------------------------------------------------------------|:------------|
| `env`                       | `${{env.HOME}}`                                               | Access environment variables set in the execution environment or in previous steps. |
| `export_file`               | `echo '{"name":"NAME","value":"Fred"}' >${{export_file}}`     | The path to the [export file](#export-an-environment-variable). Write to this file to export environment variables for use by subsequent running steps. |
| `inputs`                    | `${{inputs.message}}`                                         | Access the step's inputs. |
| `job`                       | `${{job.GITLAB_USER_NAME}}`                                   | Access GitLab CI/CD variables, limited to those starting with `CI_`, `DOCKER_` or `GITLAB_`. |
| `output_file`               | `echo '{"name":"meaning_life","value":42}' >${{output_file}}` | The path to the [output file](#return-an-output). Write to this file to set output variables from the step. |
| `step_dir`                  | `work_dir: ${{step_dir}}`                                     | The directory where the step has been downloaded. Use to refer to files in the step, or to set the working directory of an executable step. |
| `steps.[step_name].outputs` | `${{steps.my_step.outputs.name}}`                             | Access [outputs](#specify-outputs) from previously executed steps. Choose the specific step using the step name. |
| `work_dir`                  | `${{work_dir}}`                                               | The working directory of an executing step. |

Expressions are different from template interpolation which uses double square-brackets (`$[[ ]]`)
and are evaluated during job generation.

Expressions only have access to CI/CD job variables with names starting with `CI_`, `DOCKER_`,
or `GITLAB_`. Follow [epic 15073](https://gitlab.com/groups/gitlab-org/-/epics/15073)
to track when steps can access all CI/CD job variables.

### Using prior step outputs

Step inputs can reference outputs from prior steps by referencing the step name and output variable name.

For example, if the `gitlab.com/components/random-string` step defined an output variable called `random_value`:

```yaml
job:
  run:
    - name: generate_rand
      step: gitlab.com/components/random
    - name: echo_random
      step: gitlab.com/components/echo
      inputs:
        message: "The random value is: ${{steps.generate_rand.random_value}}"
```

### Environment variables

Steps can [set](#set-environment-variables) environment variables, [export](#export-an-environment-variable)
environment variables, and environment variables can be passed in when using `step`, `script`, or `action`.

Environment variable precedence, from highest to lowest precedence, are variables set:

1. By using `env` keyword in the `step.yml`.
1. By using the `env` keyword passed to a step in a sequence of steps.
1. By using the `env` keyword for all steps in a sequence.
1. Where a previously run step has written to `${{export_file}}`.
1. By the Runner.
1. By the container.

## Create your own step

Create your own step by performing the following tasks:

1. Create a GitLab project, a Git repository, or a directory on a file system that is accessible
   when the CI/CD job runs.
1. Create a `step.yml` file and place it in the root folder of the project, repository, or directory.
1. Define the [specification](#the-step-specification) for the step in the `step.yml`.
1. Define the [definition](#the-step-definition) for the step in the `step.yml`.
1. Add any files that your step uses to the project, repository, or directory.

After the step is created, you can [use the step in a job](#run-a-step).

### The step specification

The step specification is the first of two documents contained in the step `step.yml`.
The specification defines inputs and outputs that the step receives and returns.

#### Specify inputs

Input names can only use alphanumeric characters and underscores, and must not start with a number.
Inputs must have a type, and they can optionally specify a default value. An input with no default value
is a required input, it must be specified when using the step.

Inputs must be one of the following types.

| Type      | Example                 | Description |
|:----------|:------------------------|:------------|
| `array`   | `["a","b"]`             | A list of un-typed items. |
| `boolean` | `true`                  | True or false. |
| `number`  | `56.77`                 | 64 bit float. |
| `string`  | `"brown cow"`           | Text.       |
| `struct`  | `{"k1":"v1","k2":"v2"}` | Structured content. |

For example, to specify that the step accepts an optional input called `greeting` of type `string`:

```yaml
spec:
  inputs:
    greeting:
      type: string
      default: "hello, world"
---
```

To provide the input when using the step:

```yaml
run:
  - name: my_step
    step: ./my-step
    inputs:
      greeting: "hello, another world"
```

#### Specify outputs

Similar to inputs, output names can only use alphanumeric characters and underscores,
and must not start with a number. Outputs must have a type, and they can optionally specify a default value.
The default value is returned when the step doesn't return the output.

Outputs must be one of the following types.

| Type         | Example                 | Description |
|:-------------|:------------------------|:------------|
| `array`      | `["a","b"]`             | A list of un-typed items. |
| `boolean`    | `true`                  | True or false. |
| `number`     | `56.77`                 | 64 bit float. |
| `string`     | `"brown cow"`           | Text.       |
| `struct`     | `{"k1":"v1","k2":"v2"}` | Structured content. |

For example, to specify that the step returns an output called `value` of type `number`:

```yaml
spec:
  outputs:
    value:
      type: number
---
```

To use the output when using the step:

```yaml
run:
  - name: random_generator
    step: ./random-generator
  - name: echo_number
    step: ./echo
    inputs:
      message: "Random number generated was ${{step.random-generator.outputs.value}}"
```

#### Specify delegated outputs

Instead of specifying output names and types, outputs can be entirely delegated to a sub-step.
The outputs returned by the sub-step are returned by your step. The `delegate` keyword
in the step definition determines which sub-step outputs are returned by the step.

For example, the following step returns outputs returned by the `random-generator`.

```yaml
spec:
  outputs: delegate
---
run:
  - name: random_generator
    step: ./random-generator
delegate: random-generator
```

#### Specify no inputs or outputs

A step might not require any inputs or return any outputs. This could be when a step
only writes to disk, sets an environment variable, or prints to STDOUT. In this case,
`spec:` is empty:

```yaml
spec:
---
```

### The step definition

Steps can:

- Set environment variables
- Execute a command
- Run a sequence of other steps.

#### Set environment variables

Set environment variables by using the `env` keyword. Environment variable names can only use
alphanumeric characters and underscores, and must not start with a number.

Environment variables are made available either to the executable command or to all of the steps
if running a sequence of steps. For example:

```yaml
spec:
---
env:
  FIRST_NAME: Sally
  LAST_NAME: Seashells
run:
  # omitted for brevity
```

Steps only have access to a subset of environment variables from the runner environment.
Follow [epic 15073](https://gitlab.com/groups/gitlab-org/-/epics/15073+) to track
when steps can access all environment variables.

#### Execute a command

A step declares it executes a command by using the `exec` keyword. The command must be specified,
but the working directory (`work_dir`) is optional. Environment variables set by the step
are available to the running process.

For example, the following step prints the step directory to the job log:

```yaml
spec:
---
exec:
  work_dir: ${{step_dir}}
  command:
    - bash
    - -c
    - "echo ${PWD}"
```

NOTE:
Any dependency required by the executing step should also be installed by the step.
For example, if a step calls `go`, it should first install it.

##### Return an output

Executable steps return an output by adding a line to the `${{output_file}}` in JSON Line format.
Each line is a JSON object with `name` and `value` key pairs. The `name` must be a string,
and the `value` must be a type that matches the output type in the step specification:

| Step specification type | Expected JSONL value type |
|:------------------------|:--------------------------|
| `array`                 | `array`                   |
| `boolean`               | `boolean`                 |
| `number`                | `number`                  |
| `string`                | `string`                  |
| `struct`                | `object`                  |

For example, to return the output named `car` with `string` value `Range Rover`:

```yaml
spec:
  outputs:
    car:
      type: string
---
exec:
  command:
    - bash
    - -c
    - echo '{"name":"car","value":"Range Rover"}' >${{output_file}}
```

##### Export an environment variable

Executable steps export an environment variable by adding a line to the `${{export_file}}` in JSON Line format.
Each line is a JSON object with `name` and `value` key pairs. Both `name` and `value` must be strings.

For example, to set the variable `GOPATH` to value `/go`:

```yaml
spec:
---
exec:
  command:
    - bash
    - -c
    - echo '{"name":"GOPATH","value":"/go"}' >${{export_file}}
```

#### Run a sequence of steps

A step declares it runs a sequence of steps using the `steps` keyword. Steps run one at a time
in the order they are defined in the list. This syntax is the same as the `run` keyword.

Steps must have a name consisting only of alphanumeric characters and underscores, and must not start with a number.

For example, this step installs Go, then runs a second step that expects Go to already
have been installed:

```yaml
spec:
---
run:
  - name: install_go
    step: ./go-steps/install-go
    inputs:
      version: "1.22"
  - name: format_go_code
    step: ./go-steps/go-fmt
    inputs:
      code: path/to/go-code
```

##### Return an output

Outputs are returned from a sequence of steps by using the `outputs` keyword.
The type of value in the output must match the type of the output in the step specification.

For example, the following step returns the installed Java version as an output.
This assumes the `install_java` step returns an output named `java_version`.

```yaml
spec:
  outputs:
    java_version:
      type: string
---
run:
  - name: install_java
    step: ./common/install-java
outputs:
  java_version: "the java version is ${{steps.install_java.outputs.java_version}}"
```

Alternatively, all outputs of a sub-step can be returned using the `delegate` keyword.
For example:

```yaml
spec:
  outputs: delegate
---
run:
  - name: install_java
    step: ./common/install-java
delegate: install_java
```

## Combine CI/CD Components and CI/CD Steps

[CI/CD components](../components/_index.md) are reusable single pipeline configuration units. They are included in a pipeline when it is
created, adding jobs and configuration to the pipeline. Files such as common scripts or programs
from the component project cannot be referenced from a CI/CD job.

CI/CD Steps are reusable units of a job. When the job runs, the referenced step is downloaded to
the execution environment or image, bringing along any extra files included with the step.
Execution of the step replaces the `script` in the job.

Components and steps work well together to create solutions for CI/CD pipelines. Steps handle the complexity of
how jobs are composed, and automatically retrieve the files necessary to run the job. Components provide
a method to import job configuration, but hide the underlying job composition from the user.

Steps and components use different syntax for expressions to help differentiate the expression types.
Component expressions use square brackets `$[[ ]]` and are evaluated during pipeline creation.
Step expressions use braces `${{ }}` and are evaluated during job execution, just before executing the step.

For example, a project could use a component that adds a job to format Go code:

- In the project's `.gitlab-ci.yml` file:

  ```yaml
  include:
  - component: gitlab.com/my-components/go@main
    inputs:
      fmt_packages: "./..."
  ```

- Internally, the component uses CI/CD steps to compose the job, which installs Go then runs
  the formatter. In the component's `templates/go.yml` file:

  ```yaml
  spec:
    inputs:
      fmt_packages:
        description: The Go packages that will be formatted using the Go formatter.
      go_version:
        default: "1.22"
        description: The version of Go to install before running go fmt.
  ---

  format code:
    run:
      - name: install_go
        step: ./languages/go/install
        inputs:
          version: $[[ inputs.go_version ]]                    # version set to the value of the component input go_version
      - name: format_code
        step: ./languages/go/go-fmt
        inputs:
          go_binary: ${{ steps.install_go.outputs.go_binary }} # go_binary set to the value of the go_binary output from the previous step
          fmt_packages: $[[ inputs.fmt_packages ]]             # fmt_packages set to the value of the component input fmt_packages
  ```

In this example, the complexity of the steps the component author used to compose the job are hidden from the user
in the CI/CD component.
