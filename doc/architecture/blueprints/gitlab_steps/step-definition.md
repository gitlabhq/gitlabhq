---
owning-stage: "~devops::verify"
description: The Step Definition for [GitLab Steps](index.md).
---

# The Step definition

A step is the minimum executable unit that user can provide and is defined in a `step.yml` file.

The following step definition describes the minimal syntax supported.
The syntax is extended with [syntactic sugar](steps-syntactic-sugar.md).

A step definition consists of two documents. The purpose of the document split is
to distinguish between the declaration and implementation:

1. [Specification / Declaration](#step-specification):

   Provides the specification which describes step inputs and outputs,
   as well any other metadata that might be needed by the step in the future (license, author, etc.).
   In programming language terms, this is similar to a function declaration with arguments and return values.

1. [Implementation](#step-implementation):

   The implementation part of the document describes how to execute the step, including how the environment
   has to be configured, or how actions can be configured.

## Example step that prints a message to stdout

In the following step example:

1. The declaration specifies that the step accepts a single input named `message`.
   The `message` is a required argument that needs to be provided when running the step
   because it does not define `default:`.
1. The implementation section specifies that the step is of type `exec`. When run, the step
   will execute an `echo` command with a single argument (the `message` value).

```yaml
# .gitlab/ci/steps/exec-echo.yaml
spec:
  inputs:
    message:
---
type: exec
exec:
  command: [echo, "${{inputs.message}}"]
```

## Step specification

The step specification currently only defines inputs and outputs:

- Inputs:
  - Can be required or optional.
  - Have a name and can have a description.
  - Can contain a list of accepted options. Options limit what value can be provided for the input.
  - Can define matching regexp. The matching regexp limits what value can be provided for the input.
  - Can be expanded with the usage of syntax `${{ inputs.input_name }}`.
- All **input values** can be accessed when `type: exec` is used,
  by decoding the `$STEP_JSON` file that does provide information about the context of the execution.
- Outputs:
  - Have a name and can have a description.
  - Can be set by writing to a special [dotenv](https://github.com/bkeepers/dotenv) file named:
    `$OUTPUT_FILE` with a format of `output_name=VALUE` per output.

For example:

```yaml
spec:
  inputs:
    message_with_default:
      default: "Hello World"
    message_that_is_required:
      description: "This description explains that the input is required, because it does not specify a default:"
    type_with_limited_options:
      options: [bash, powershell, detect]
    type_with_default_and_limited_options:
      default: bash
      options: [bash, powershell, detect]
      description: "Since the options are provided, the default: needs to be one of the options"
    version_with_matching_regexp:
      match: ^v\d+\.\d+$
      description: "The match pattern only allows values similar to `v1.2`"
  outputs:
    code_coverage:
      description: "Measured code coverage that was calculated as part of the step"
---
type: steps
steps:
  - step: ./bash-script.yaml
    inputs:
      script: "echo Code Coverage = 95.4% >> $OUTPUT_FILE"
```

## Step Implementation

The step definition can use the following types to implement the step:

- `type: exec`: Run a binary command, using STDOUT/STDERR for tracing the executed process.
- `type: steps`: Run a sequence of steps.
- `type: parallel` (Planned): Run all steps in parallel, waiting for all of them to finish.
- `type: grpc` (Planned): Run a binary command but use gRPC for intra-process communication.
- `type: container` (Planned): Run a nested Step Runner in a container image of choice,
  transferring all execution flow.

### The `exec` step type

The ability to run binary commands is one of the primitive functions:

- The command to execute is defined by the `exec:` section.
- The result of the execution is the exit code of the command to be executed, unless the default behavior is overwritten.
- The default working directory in which the command is executed is the directory in which the
  step is located.
- By default, the command is not time-limited, but can be time-limited during job execution with `timeout:`.

For example, an `exec` step with no inputs:

```yaml
spec:
---
type: exec
exec:
  command: [/bin/bash, ./my-script.sh]
  timeout: 30m
  workdir: /tmp
```

#### Example step that executes user-defined command

The following example is a minimal step definition that executes a user-provided command:

- The declaration section specifies that the step accepts a single input named `script`.
- The `script` input is a required argument that needs to be provided when running the step
  because no `default:` is defined.
- The implementation section specifies that the step is of type `exec`. When run, the step
  will execute in `bash` passing the user command with `-c` argument.
- The command to be executed will be prefixed with `set -veo pipefail` to print the execution
  to the job log and exit on the first failure.

```yaml
# .gitlab/ci/steps/exec-script.yaml

spec:
  inputs:
    script:
      description: 'Run user script.'
---
type: exec
exec:
  command: [/usr/bin/env, bash, -c, "set -veo pipefail; ${{inputs.script}}"]
```

### The `steps` step type

The ability to run multiple steps in sequence is one of the primitive functions:

- A sequence of steps is defined by an array of step references: `steps: []`.
- The next step is run only if previous step succeeded, unless the default behavior is overwritten.
- The result of the execution is either:
  - A failure at the first failed step.
  - Success if all steps in sequence succeed.

#### Steps that use other steps

The `steps` type depends extensively on being able to use other steps.
Each item in a sequence can reference other external steps, for example:

```yaml
spec:
---
type: steps
steps:
  - step: ./.gitlab/ci/steps/ruby/install.yml
    inputs:
      version: 3.1
    env:
      HTTP_TIMEOUT: 10s
  - step: gitlab.com/gitlab-org/components/bash/script@v1.0
    inputs:
      script: echo Hello World
```

The `step:` value is a string that describes where the step definition is located:

- **Local**: The definition can be retrieved from a local source with `step: ./path/to/local/step.yml`.
  A local reference is used when the path starts with `./` or `../`.
  The resolved path to another local step is always **relative** to the location of the current step.
  There is no limitation where the step is located in the repository.
- **Remote**: The definition can also be retrieved from a remote source with `step: gitlab.com/gitlab-org/components/bash/script@v1.0`.
  Using a FQDN makes the Step Runner pull the repository or archive containing
  the step, using the version provided after the `@`.

The `inputs:` section is a list of key-value pairs. The `inputs:` specify values
that are passed and matched against the [step specification](#step-specification).

The `env:` section is a list of key-value pairs. `env:` exposes the given environment
variables to all children steps, including [`type: exec`](#the-exec-step-type) or [`type: steps`](#the-steps-step-type).

#### Remote Steps

To use remote steps with `step: gitlab.com/gitlab-org/components/bash/script@v1.0`
the step definitions must be stored in a structured-way. The step definitions:

- Must be stored in the `steps/` folder.
- Can be nested in sub-directories.
- Can be referenced by the directory name alone if the step definition
  is stored in a `step.yml` file.

For example, the file structure for a repository hosted in `git clone https://gitlab.com/gitlab-org/components.git`:

```plaintext
├── steps/
├── ├── secret_detection.yml
|   ├── sast/
│   |   └── step.yml
│   └── dast
│       ├── java.yml
│       └── ruby.yml
```

This structure exposes the following steps:

- `step: gitlab.com/gitlab-org/components/secret_detection@v1.0`: From the definition stored at `steps/secret_detection.yml`.
- `step: gitlab.com/gitlab-org/components/sast@v1.0`: From the definition stored at `steps/sast/step.yml`.
- `step: gitlab.com/gitlab-org/components/dast/java@v1.0`: From the definition stored at `steps/dast/java.yml`.
- `step: gitlab.com/gitlab-org/components/dast/ruby@v1.0`: From the definition stored at `steps/dast/ruby.yml`.

#### Example step that runs other steps

The following example is a minimal step definition that
runs other steps that are local to the current step.

- The declaration specifies that the step accepts two inputs, each with
  a default value.
- The implementation section specifies that the step is of type `steps`, meaning
  the step will execute the listed steps in sequence. The usage of a top-level
  `env:` makes the `HTTP_TIMEOUT` variable available in all executed steps.

```yaml
spec:
  inputs:
    ruby_version:
      default: 3.1
    http_timeout:
      default: 10s
---
type: steps
env:
  HTTP_TIMEOUT: ${{inputs.http_timeout}}
steps:
  - step: ./.gitlab/ci/steps/exec-echo.yaml
    inputs:
      message: "Installing Ruby ${{inputs.ruby_version}}..."
  - step: ./.gitlab/ci/ruby/install.yaml
    inputs:
      version: ${{inputs.ruby_version}}
```

## Context and interpolation

Every step definition is executed in a context object which
stores the following information that can be used by the step definition:

- `inputs`: The list of inputs, including user-provided or default.
- `outputs`: The list of expected outputs.
- `env`: The current environment variable values.
- `job`: The metadata about the current job being executed.
  - `job.project`: Information about the project, for example ID, name, or full path.
  - `job.variables`: All [CI/CD Variables](../../../ci/variables/predefined_variables.md) as provided by the CI/CD execution,
    including project variables, predefined variables, etc.
  - `job.pipeline`: Information about the current executed pipeline, like the ID, name, full path
- `step`: Information about the current executed step, like the location of the step, the version used, or the [specification](#step-specification).
- `steps` (only for `type: exec`): - Information about each step in sequence to be run, containing information about the
  result of the step execution, like status or trace log.
  - `steps.<name-of-the-step>.status`: The status of the step, like `success` or `failed`.
  - `steps.<name-of-the-step>.outputs.<output-name>`: To fetch the output provided by the step

The context object is used to enable support for the interpolation in the form of `${{ <value> }}`.

Interpolation:

- Is forbidden in the [step specification](#step-specification) section.
  The specification is static configuration that should not affected by the runtime environment.
- Can be used in the [step implementation](#step-implementation) section. The implementation
  describes the runtime set of instructions for how step should be executed.
- Is applied to every value of the hash of each data structure.
- Of the *values* of each hash is possible (for now). The interpolation of *keys* is forbidden.
- Is done when executing and passing control to a given step, instead of running
  it once when the configuration is loaded. This enables chaining outputs to inputs, or making steps depend on the execution
  of earlier steps.

For example:

```yaml
# .gitlab/ci/steps/exec-echo.yaml
spec:
  inputs:
    timeout:
      default: 10s
    bash_support_version:
---
type: steps
env:
  HTTP_TIMEOUT: ${{inputs.timeout}}
  PROJECT_ID: ${{job.project.id}}
steps:
  - step: ./my/local/step/to/echo.yml
    inputs:
      message: "I'm currently building a project: ${{job.project.full_path}}"
  - step: gitlab.com/gitlab-org/components/bash/script@v${{inputs.bash_support_version}}
```

## Reference data structures describing YAML document

```go
package main

type StepEnvironment map[string]string

type StepSpecInput struct {
    Default     *string   `yaml:"default"`
    Description string    `yaml:"description"`
    Options     *[]string `yaml:"options"`
    Match       *string   `yaml:"match"`
}

type StepSpecOutput struct {
}

type StepSpecInputs map[string]StepSpecInput
type StepSpecOutputs map[string]StepSpecOutput

type StepSpec struct {
    Inputs  StepSpecInput   `yaml:"inputs"`
    Outputs StepSpecOutputs `yaml:"outputs"`
}

type StepSpecDoc struct {
    Spec StepSpec `yaml:"spec"`
}

type StepType string

const StepTypeExec StepType = "exec"
const StepTypeSteps StepType = "steps"

type StepDefinition struct {
    Def   StepSpecDoc             `yaml:"-"`
    Env   StepEnvironment         `yaml:"env"`
    Steps *StepDefinitionSequence `yaml:"steps"`
    Exec  *StepDefinitionExec     `yaml:"exec"`
}

type StepDefinitionExec struct {
    Command    []string       `yaml:"command"`
    WorkingDir *string        `yaml:"working_dir"`
    Timeout    *time.Duration `yaml:"timeout"`
}

type StepDefinitionSequence []StepReference

type StepReferenceInputs map[string]string

type StepReference struct {
    Step   string              `yaml:"step"`
    Inputs StepReferenceInputs `yaml:"inputs"`
    Env    StepEnvironment     `yaml:"env"`
}
```
