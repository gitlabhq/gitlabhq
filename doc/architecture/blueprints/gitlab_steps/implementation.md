---
owning-stage: "~devops::verify"
description: Implementation details for [CI Steps](index.md).
---

# Design and implementation details

## Baseline Step Proto

The internals of Step Runner operate on the baseline step definition
which is defined in Protocol Buffer. All GitLab CI steps (and other
supported formats such as GitHub Actions) compile / fold to baseline steps.
Both step invocations in `.gitlab-ci.yml` and step definitions
in `step.yml` files will be compiled to baseline structures.
The term "step" means "baseline step" for the remainder of this document.

Each step includes a reference `ref` in the form of a URI. The method of
retrieval is determined by the protocol of the URI.

Steps and step traces have fields for inputs, outputs,
environment variables and environment exports.
After steps are downloaded and the `step.yml` is parsed
a step definition `def` will be added.
If a step defines multiple additional steps then the
trace will include sub-traces for each sub-step.

```protobuf
message Step {
    string name = 1;
    string step = 2;
    map<string,string> env = 3;
    map<string,google.protobuf.Value> inputs = 4;
}

message Definition {
    DefinitionType type = 1;
    Exec exec = 2;
    repeated Step steps = 3;
    message Exec {
        repeated string command = 1;
        string work_dir = 2;
    }
}

enum DefinitionType {
    definition_type_unspecified = 0;
    exec = 1;
    steps = 2;
}

message Spec {
    Content spec = 1;
    message Content {
        map<string,Input> inputs = 1;
        message Input {
            InputType type = 1;
            google.protobuf.Value default = 2;
        }
    }
}

enum InputType {
    spec_type_unspecified = 0;
    string = 1;
    number = 2;
    bool = 3;
    struct = 4;
    list = 5;
}

message StepResult {
    Step step = 1;
    Spec spec = 2;
    Definition def = 3;
    enum Status {
        unspecified = 0;
        running = 1;
        success = 2;
        failure = 3;
    }
    Status status = 4;
    map<string,Output> outputs = 5;
    message Output {
        string key = 1;
        string value = 2;
        bool masked = 3;
    }
    map<string,string> exports = 6;
    int32 exit_code = 7;
    repeated StepResult children_step_results = 8;
}
```

## Step Caching

Steps are cached locally by a key comprised of `location`
(URL), `version` and `hash`. This prevents the exact same component
from being downloaded multiple times. The first time a step is
referenced it will be downloaded (unless local) and the cache will
return the path to the folder containing `step.yml` and the other
step files. If the same step is referenced again, the same folder
will be returned without downloading.

If a step is referenced which differs by version or hash from another
cached step, it will be re-downloaded into a different folder and
cached separately.

## Execution Context

State is kept by Step Runner across all steps in the form of
an execution context. The context contains the output of each step,
environment variables and overall job and environment metadata.
The execution context can be referenced by expressions in
GitLab CI steps provided by the workflow author.

Example of context available to expressions in `.gitlab-ci.yml`:

```yaml
steps:
  previous_step:
    outputs:
      name: "hello world"
env:
  EXAMPLE_VAR: "bar"
job:
  id: 1234
```

Expressions in step definitions can also reference execution
context. However they can only access overall
job and environment metadata and the inputs defined in `step.yml`.
They cannot access the outputs of previous steps. In order to
provide the output of one step to the next, the step input
values should include an expression which references another
step's output.

Example of context available to expressions in `step.yml`:

```yaml
inputs:
  name: "foo"
env:
  EXAMPLE_VAR: "bar"
job:
  id: 1234
```

E.g. this is not allowed in a `step.yml file` because steps
should not couple to one another.

```yaml
spec:
  inputs:
    name:
---
type: exec
exec:
  command: [echo, hello, ${{ steps.previous_step.outputs.name }}]
```

This is allowed because the GitLab CI steps syntax passes data
from one step to another:

```yaml
spec:
  inputs:
    name:
---
type: exec
exec:
  command: [echo, hello, ${{ inputs.name }}]
```

```yaml
steps:
- name: previous_step
  ... 
- name: greeting
  inputs:
    name: ${{ steps.previous_step.outputs.name }}
```

Therefore evaluation of expressions will done in two different kinds
of context. One as a GitLab CI Step and one as a step definition.

### Step Inputs

Step inputs can be given in several ways. They can be embeded
directly into expressions in an `exec` command (as above). Or they
can be embedded in expressions for environment variables set during
exec:

```yaml
spec:
  inputs:
    name:
---
type: exec
exec:
  command: [greeting.sh]
env:
  NAME: ${{ inputs.name }}
```

### Input Types

Input values are stored as strings. But they can also have a type
associated with them. Supported types are:

- `string`
- `bool`
- `number`
- `object`

String type values can be any string. Bool type values must be either `true`
or `false` when parsed as JSON. Number type values must a valid float64
when parsed as JSON. Object types will be a JSON serialization of
the YAML input structure.

For example, these would be valid inputs:

```yaml
steps:
- name: my_step
  inputs:
    foo: bar
    baz: true
    bam: 1
```

Given this step definition:

```yaml
spec:
  inputs:
    foo:
      type: string
    baz:
      type: bool
    bam:
      type: number
---
type: exec
exec:
  command: [echo, ${{ inputs.foo }}, ${{ inputs.baz }}, ${{ inputs.bam }}]
```

And it would output `bar true 1`

For an object type, these would be valid inputs:

```yaml
steps:
  name: my_step
  inputs:
    foo:
      steps:
      - name: my_inner_step
        inputs:
          name: steppy
```

Given this step definition:

```yaml
spec:
  inputs:
    foo:
      type: object
---
type: exec
exec:
  command: [echo, ${{ inputs.foo }}]
```

And it would output `{"steps":[{"name":"my_inner_step","inputs":{"name":"steppy"}}]}`

### Outputs

Output files are created into which steps can write their
outputs and environment variable exports. The file locations are
provided in `OUTPUT_FILE` and `ENV_FILE` environment variables.

After execution Step Runner will read the output and environment
variable files and populate the trace with their values. The
outputs will be stored under the context for the executed step.
And the exported environment variables will be merged with environment
provided to the next step.

Some steps can be of type `steps` and be composed of a sequence
of GitLab CI steps. These will be compiled and executed in sequence.
Any environment variables exported by nested steps will be available
to subsequent steps. And will be available to high level steps
when the nested steps are complete. E.g. entering nested steps does
not create a new "scope" or context object. Environment variables
are global.

## Containers

We've tried a couple approaches to running steps in containers.
In end we've decided to delegate steps entirely to a step runner
in the container.

Here are the options considered:

### Delegation (chosen option)

A provision is made for passing complex structures to steps, which
is to serialize them as JSON (see Inputs above). In this way the actual
step to be run can be merely a parameter to step running in container.
So the outer step is a `docker/run` step with a command that executes
`step-runner` with a `steps` input parameter. The `docker/run` step will
run the container and then extract the output files from the container
and re-emit them to the outer steps.

This same technique will work for running steps in VMs or whatever.
Step Runner doesn't have to know anything about containerizing or
isolation steps.

### Special Compilation (rejected option)

When we see the `image` keyword in a GitLab CI step we would download
and compile the "target" step. Then manufacture a `docker/run` step
and pass the complied `exec` command as an input. Then we would compile
the `docker/run` step and execute it.

However this requires Step Runner to know how to construct a `docker/run`
step. Which couples Step Runner with the method of isolation, making
isolation in VMs and other methods more complicated.

### Native Docker (rejected option)

The baseline step can include provisions for running a step in a
Docker container. For example the step could include a `ref` "target"
field and an `image` field.

However this also couples Step Runner with Docker and expands the role
of Step Runner. It is preferable to make Docker an external step
that Step Runner execs in the same way as any other step.
