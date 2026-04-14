---
stage: Verify
group: CI Functions Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Create a GitLab Function
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Experiment

{{< /details >}}

A GitLab Function is a directory with a `func.yml` file that defines the function's interface
and implementation. Functions can run locally or be published to an OCI registry for reuse across
jobs and projects.

For information on using functions in a CI/CD job, see [GitLab Functions](_index.md). For example functions,
see [GitLab Functions examples](examples.md).

## Function structure

A function is a directory that contains at a minimum a `func.yml` file, plus any supporting
files the implementation needs:

```plaintext
my-function/
├── func.yml
└── my-script.sh
```

The `func.yml` file contains two YAML documents separated by `---`: a spec that
defines the function's inputs and outputs, and a definition that describes what
the function does.

```yaml
# Document 1: spec
spec:
  inputs:
    message:
      type: string
  outputs:
    result:
      type: string
---
# Document 2: definition
exec:
  command: ["${{ func_dir }}/my-script.sh", "${{ inputs.message }}"]
```

## Spec: Declare inputs and outputs

The spec describes the function's interface.

### Inputs

Each input requires a `type`. Inputs with a `default` value are optional. Inputs without
a default value must be provided by the caller.

Input names must use alphanumeric characters and underscores, and cannot start with a number.

Inputs must be one of these types:

| Type      | Example                 | Description             |
|:----------|:------------------------|:------------------------|
| `array`   | `["a","b"]`             | A list of untyped items |
| `boolean` | `true`                  | True or false           |
| `number`  | `56.77`                 | 64-bit float            |
| `string`  | `"brown cow"`           | Text                    |
| `struct`  | `{"k1":"v1","k2":"v2"}` | Structured content      |

For example:

```yaml
spec:
  inputs:
    # Required string input
    message:
      type: string

    # Optional input with a default
    count:
      type: number
      default: 1

    # Struct input for passing structured data
    config:
      type: struct
      default: {}
```

### Outputs

Outputs define the values the function returns to subsequent steps. Each output requires a `type`.
Outputs with a `default` value are optional. The default value is used when the function doesn't
write the output value.

Outputs use the same types and naming rules as inputs.

For example:

```yaml
spec:
  outputs:
    # Required string output
    artifact_path:
      type: string

    # Optional output with a default
    compressed:
      type: boolean
      default: false
```

At runtime, the function writes output values to the path given by `${{ output_file }}`.
Each line must be a JSON object with `name` and `value` fields:

```shell
echo '{"name":"artifact_path","value":"/dist/app.tar.gz"}' >> "${{ output_file }}"
echo '{"name":"compressed","value":true}' >> "${{ output_file }}"
```

### Delegate outputs

If a function has multiple steps and you want the function's outputs to come from one specific
step, use `outputs: delegate` in the spec and `delegate: <step_name>` in the definition:

```yaml
spec:
  outputs: delegate
---
run:
  - name: build
    func: ./build
  - name: package
    func: ./package
delegate: package  # use the package step outputs as this function outputs
```

## Definition: Implement the function

The second document in `func.yml` describes the implementation. You can
implement a function in two ways.

### `exec`

Use `exec` to run a single command or script. The command is passed
directly to the OS without a shell, so it must be an array of strings.

```yaml
spec:
  inputs:
    message:
      type: string
---
exec:
  command: ["./greet", "${{ inputs.message }}"]
```

The working directory defaults to `CI_PROJECT_DIR`. To override it, use `work_dir`.
The `work_dir` keyword is valid only for `exec` definitions, not `run:` definitions.

Set `work_dir` to `${{ func_dir }}` when the command needs to reference
files in the same directory as `func.yml`:

```yaml
exec:
  command: ["./build.sh"]
  work_dir: "${{ func_dir }}"
```

The function fails if the command exits with a non-zero exit code.

### `run`

Use `run` for a function that calls other functions in sequence.

The function fails if any step in the sequence fails. Subsequent steps in the sequence do not run after a failure.

```yaml
spec:
  inputs:
    environment:
      type: string
  outputs:
    url:
      type: string
---
run:
  - name: build
    func: ./build
  - name: push
    func: registry.example.com/my-org/push:1.0.0
    inputs:
      artifact: ${{ steps.build.outputs.artifact_path }}
  - name: deploy
    func: ./deploy
    inputs:
      env: ${{ inputs.environment }}
      image: ${{ steps.push.outputs.image_ref }}
outputs:
  url: ${{ steps.deploy.outputs.url }}
```

### Set environment variables

Use `env` in the definition to set environment variables for the `exec` command
or for all steps in a `run:` sequence. Values can use expressions:

```yaml
spec:
---
run:
  - name: test
    func: ./run-tests
env:
  GOFLAGS: "-race"
  TARGET_ENV: "${{ inputs.environment }}"
```

## Export environment variables

To make an environment variable available to all steps that run after your function
for the remainder of the job, write it to `${{ export_file }}`. Each line must be a JSON object
with `name` and `value` fields:

```shell
echo '{"name":"INSTALL_PATH","value":"/opt/myapp"}' >> "${{ export_file }}"
```

Only `string`, `number`, and `boolean` values can be exported as environment variables.

For more information about how exported variables interact with `env:` and the wider environment, see
[environment variables](_index.md#environment-variables).

## Expressions

Expressions use the `${{ }}` syntax and are evaluated just before the function runs.
They can appear in `inputs` values, `env` values, `exec` command arguments, and `work_dir`.

The following context variables are available inside a function definition, in addition
to those described in [expressions](_index.md#expressions):

| Variable                                  | Description                                                                                 |
|:------------------------------------------|:--------------------------------------------------------------------------------------------|
| `inputs.<name>`                           | The value of the named input passed to this function.                                       |
| `func_dir`                                | Absolute path to the directory containing this `func.yml`. Use to reference bundled files.  |
| `output_file`                             | Path to the file for writing outputs.                                                       |
| `export_file`                             | Path to the file for exporting environment variables.                                       |
| `steps.<step_name>.outputs.<output_name>` | Output from a named step (available in `run:` definitions only).                            |

## Complete example

The following function accepts a file path, compresses it with `gzip`, and returns the
path to the compressed file.

### Create the function

Directory layout:

```plaintext
compress/
├── func.yml
└── compress.sh
```

`func.yml`:

```yaml
spec:
  inputs:
    input_path:
      type: string
  outputs:
    output_path:
      type: string
---
exec:
  command: ["${{ func_dir }}/compress.sh", "${{ inputs.input_path }}", "${{ output_file }}"]
```

`compress.sh` (must be executable):

```shell
#!/usr/bin/env sh
set -e

INPUT_PATH="$1"
OUTPUT_FILE="$2"

gzip --keep "$INPUT_PATH"

echo "{\"name\":\"output_path\",\"value\":\"${INPUT_PATH}.gz\"}" >> "$OUTPUT_FILE"
```

### Use the function from a job

This function requires `gzip` in the job environment. This example assumes
`gzip` is already available on the instance where the job runs. If it is
not, you can install it first with a `script:` step, or invoke a function that handles
the installation before calling `compress`.

```yaml
my-job:
  run:
    - name: compress_artifact
      func: ./compress
      inputs:
        input_path: "dist/app.tar"
    - name: list_compressed
      script: ls -lh ${{ steps.compress_artifact.outputs.output_path }}
```

For more example functions, see [GitLab Functions examples](examples.md).

## Build and release functions

Functions are distributed as OCI images. The step runner provides two built-in functions
for building and publishing function images.

### Build

The `builtin://function/oci/build` function builds a multi-architecture function OCI image from files in the project
directory and archives it as `function-image.tar` in the `CI_PROJECT_DIR`.

`common.files` copies files shared across all platforms. `platforms.<os/arch>.files`
copies files specific to that platform. In both cases, map keys are destination paths
in the image and values are source paths relative to `CI_PROJECT_DIR`.

In the following example, `function-image.tar` is a function OCI image that supports two platforms: `linux/amd64` and
`linux/arm64`. Each platform image has three files: `func.yml`, `my-script.sh`, and `bin/my-binary`. Using the same filename
for platform binaries keeps `func.yml` platform-independent.

<!-- vale gitlab_base.Substitutions = NO -->
```yaml
build_function:
  artifacts:
    paths:
      - function-image.tar
  run:
    - name: build
      func: builtin://function/oci/build
      inputs:
        version: "1.2.3"
        common:
          files:
            func.yml: func.yml
            my-script.sh: my-script.sh
        platforms:
          linux/amd64:
            files:
              bin/my-binary: bin/linux-amd64/my-binary
          linux/arm64:
            files:
              bin/my-binary: bin/linux-arm64/my-binary
```
<!-- vale gitlab_base.Substitutions = YES -->

### Release

The `builtin://function/oci/publish` function publishes the archive from `function/oci/build` to an OCI registry.

The publish function uses semantic versioning for function image tags: `1.0.0`, `1.1.0`, `2.0.0`. The function extracts the
version from the `function-image.tar` file. Publish updates the `major`, `major.minor`, `major.minor.patch`
and `latest` tags where necessary.

Release candidates use a pre-release suffix such as `1.2.0-rc1`. Publishing a release
candidate creates only the exact `major.minor.patch-prerelease` tag. It does not update
`major`, `major.minor`, or `latest` tags.

```yaml
publish_function:
  needs: [build_function]
  run:
    - name: publish
      func: builtin://function/oci/publish
      inputs:
        archive: function-image.tar  # version is baked into the tar file
        to_repository: registry.example.com/my-org/my-function
```

### Authenticate to a registry

To publish to a private registry, authenticate before running `function/oci/publish`.
Use the [Docker Auth](https://gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/docker-auth)
function to generate and export `DOCKER_AUTH_CONFIG` as a step before you publish:

```yaml
publish_function:
  needs: [build_function]
  run:
    - name: auth
      func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/docker-auth:1
      inputs:
        registry: ${{ vars.CI_REGISTRY }}
        username: ${{ vars.CI_REGISTRY_USER }}
        password: ${{ vars.CI_REGISTRY_PASSWORD }}
    - name: publish
      func: builtin://function/oci/publish
      inputs:
        archive: function-image.tar
        to_repository: ${{ vars.CI_REGISTRY_IMAGE }}
```

`docker-auth` exports `DOCKER_AUTH_CONFIG` to all subsequent steps, so `function/oci/publish`
picks it up automatically.

Once published, callers reference the function using the registry URL and a tag:

```yaml
run:
  - name: run_my_function
    func: registry.example.com/my-org/my-function:1.2.3
```
