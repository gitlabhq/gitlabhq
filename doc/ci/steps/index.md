---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# CI/CD steps

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated
**Status:** Experimental

Steps are reusable and composable pieces of a job.
Each step defines structured inputs and outputs that can be consumed by other steps.
Steps can come from local files, GitLab.com repositories, or any other Git source.

To get started, see the [Set up steps tutorial](../../tutorials/setup_steps/index.md).

Support for a CI Catalog that publishes steps is proposed in [issue 425891](https://gitlab.com/gitlab-org/gitlab/-/issues/425891).

## Define steps

Steps are defined in a `step.yml` file.
Each file has two documents, the spec and the definition.

The spec provides inputs, outputs, types, descriptions, and defaults.

```yaml
# Example spec
spec:
  inputs:
    name:
      type: string
      default: joe steppy
---
# (definition goes here)
```

The definition provides the implementation of the step.
There are two kinds of step definitions:

- The `exec` type, which executes a command.

   ```yaml
   # (spec goes here)
   ---
   # Example exec definition
   exec:
   command: [ docker, run, -it, ubuntu, uname, -a ]
   ```

- The `steps` type, which runs a sequence of other steps.

   ```yaml
   # (spec goes here)
   ---
   # Example steps definition
   steps:
     - name: greet_user
       step: gitlab.com/gitlab-org/ci-cd/runner-tools/echo-step@v1
       inputs:
         echo: hello ${{ inputs.name }}
     - name: print_system_information
       step: ./my-local-steps/uname
   ```

So that you can refactor step implementations, you can change steps from `exec` to `steps` type, and from `exec` to `steps` type without an affect on workflows (or calling steps).

### Inputs

Inputs can be the following types:

- `string`
- `number`
- `boolean`
- `array`
- `struct`

The default input type is `string`.

If an input doesn't define a default then it is required.
Defaults cannot use expressions (`${{ }}`) that are only permitted in the step definition.

### Outputs

Outputs can be the following types:

- `string`
- `number`
- `boolean`
- `array`
- `struct`
- `raw_string`
- `step_result`

Outputs are written to `${{ output_file }}` in the form `key=value` where `key` is the name of the output.
The `value` should be written as JSON unless the type is `raw_string`.
The value type written by the step must match the declared type. The default output type is `raw_string`.

The special output type `step_result` is used when delegating step execution to another step.
For example, the `script` and `action-runner` steps.

Outputs for `steps` type definitions use expressions to aggregate from sub-step outputs.
Because expressions are not permitted in the spec, the `outputs` keyword appear in the definition.
To preserve encapsulation and allow refactoring, callers cannot directly access outputs from sub-steps.

```yaml
# Example output from multiple steps
spec:
  outputs:
    full_name:
      type: string
---
steps:
  - name: first_name
    step: ./fn
  - name: last_name
    step: ./ln
outputs:
  full_name: "hello ${{ steps.first_name.outputs.name }} ${{ steps.last_name.outputs.name }}"
```

## Using steps

The keyword `step` points to a remote or local step.

Remote step references are the URL of a Git repo, the character `@`, and the tag or branch (version).
Step runner looks for a file `step.yml` at the root of the repository.

Local steps begin with `.` and point to a directory where step-runner looks for `step.yml`.
Local references always use the path separator `/` regardless of operating system.
The OS appropriate separate is used when loading the file.

```yaml
# Example job using steps
my-job:
  run:
    - name: greet_user
      step: gitlab.com/gitlab-org/ci-cd/runner-tools/echo-step@v1
      inputs:
        echo: hello $[[ GITLAB_USER_LOGIN ]]
    - name: print_system_information
      step: ./my-local-steps/uname
```

To use steps in a job, provide steps in a variable and invoke the step runner the job `script` keyword. Support to use steps in a job as a `run` keyword in a GitLab CI pipeline configuration is proposed in [epic 11525](https://gitlab.com/groups/gitlab-org/-/epics/11525).

```yaml
# Example work-around until run keyword is implemented
my-job:
  image: registry.gitlab.com/gitlab-org/step-runner:v0
  variables:
    STEPS: |
      - name: greet_user
        step: gitlab.com/gitlab-org/ci-cd/runner-tools/echo-step@v1
        inputs:
          echo: hello $GITLAB_USER_LOGIN
      - name: print_system_information
        step: ./my-local-steps/uname
  script:
    # Run the step-runner's ci command which ready from the STEPS environment variable
    - /step-runner ci
```

### Set environment variables

You do not need to declare environment variables for steps.
Any exports written to `${{ export_file }}` in the form `key=value` are added to the global execution environment.
Exported values are plain strings (no JSON).

You can use the `env` keyword for steps to temporarily set environment variables during their execution:

```yaml
# Example job using env
my-job:
  run:
    - name: greet_user
      step: gitlab.com/gitlab-org/ci-cd/runner-tools/echo-step@v1
      env:
        USER: $[[ GITLAB_USER_LOGIN ]]
      inputs:
        echo: hello ${{ env.USER }}
```

Step definitions can also temporarily set environment variables.

```yaml
# (spec goes here)
---
# Example step definition using env
env:
  USER: ${{ inputs.user }}
steps:
  - name: greet_user
    step: gitlab.com/gitlab-org/ci-cd/runner-tools/echo-step@v1
    inputs:
      echo: hello ${{ env.USER }}
```

The order of precedence for environment variables is:

1. Step definition
1. Step reference (calling a step)
1. Global environment

The `env` variables set in a step definition override variables that are set when the step is called, and so on.

### Running steps locally

To run steps locally, [download `step-runner`](https://gitlab.com/gitlab-org/step-runner) and run the `ci` command.
This is the same binary that is used to run steps in production.

```shell
STEPS=$(yq '."my-job"'.run .gitlab-ci.yml) step-runner ci
```

You can debug with [`delve`](https://github.com/go-delve/delve).
Set a break point at [`Run` in `pkg/runner.go`](https://gitlab.com/gitlab-org/step-runner/-/blob/ac25318db27ed049dc3ce0fd7d9ce507d215b690/pkg/runner/runner.go#L57).

```shell
STEPS=$(yq '."my-job"'.run .gitlab-ci.yml) dlv debug . ci
```

## Scripts

Steps is an alternative to shell scripts for running jobs.
They provide more structure, can be composed, and can be tested and reused.
A `exec:command` is run by using an Exec system call, not by running a shell.

However sometimes a shell script is what's needed.
The `script` keyword will automatically select the correct shell and runs a script.

```yaml
# Example job using script
my-job:
  run:
    - name: greet_user
      script: echo hello $[[ GITLAB_USER_LOGIN ]]
```

NOTE:
Only the `bash` shell is supported. Support for conditional expressions is proposed in [epic 12168](https://gitlab.com/groups/gitlab-org/-/epics/12168).

## Actions

You can run GitHub actions with the `action` keyword.
Inputs and outputs work the same way as steps.
Steps and actions can be used interchangably.

```yaml
# Example job using action
my-job:
  run:
    - name: greet_user
      step: gitlab.com/gitlab-org/ci-cd/runner-tools/echo-step@v1
      inputs:
        echo: hello $[[ GITLAB_USER_LOGIN ]]
    - name: greet_user_again
      action: mikefarah/yq@master
      inputs:
        cmd: echo ["${{ steps.greet_user.outputs.echo }} again!"] | yq .[0]
```

### Known issues

Actions running in GitLab do not support uploading artifacts directly.
Artifacts must be written to the file system and cache instead, and selected with the existing [`artifacts` keyword](../yaml/index.md#artifacts).

Running actions requires the `dind` service.
For more information, see [Use Docker to build Docker images](../docker/using_docker_build.md).

Actions in GitLab are experimental and may contain bugs.
To report a bug, create an issue in the [action-runner repo](https://gitlab.com/components/action-runner/-/issues).

## Expressions

Expressions is a mini-language enclosed in double curly-braces (`${{ }}`)
They can reference `inputs`, `env` (the environment shared by steps) and the outputs of previous steps (`steps.<step_name>.outputs`).

Expressions can also reference `work_dir` which is the build directory.
And `step_dir` where the step definition and associated files are cached.
As well as `output_file` and `export_file` which is where outputs and exports are to be written.

Expressions are different from template interpolation which uses double square-brackets (`$[[ ]]`) and is evaluated during job generation.
Expressions are evaluated just before step execution in the job environment.
