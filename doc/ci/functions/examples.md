---
stage: Verify
group: CI Functions Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Functions examples
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Experiment

{{< /details >}}

The following examples use Google distroless image, which includes `ca-certificates` but has no package manager or shell.
You can use any image with trusted CA root certificates installed.

## Echo a message

Echoes a message for use in subsequent steps.
For full source code, see [echo](https://gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/echo).

Function definition:

```yaml
spec:
  inputs:
    message:
      type: string
      default: "Hello World!"
      description: "The message to print to stdout"
  outputs:
    message:
      type: string
---
exec:
  command:
    - ${{ func_dir }}/echo
    - --message
    - ${{ inputs.message }}
    - --output-file
    - ${{ output_file }}
```

Usage:

```yaml
my-job:
  image: gcr.io/distroless/static-debian12
  run:
    - name: echo_hi
      func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/echo:1
      inputs:
        message: "Hi, ${{ vars.GITLAB_USER_NAME }}"
    - name: echo_repeat
      func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/echo:1
      inputs:
        message: "The echo_hi step said: ${{ steps.echo_hi.outputs.message }}"
```

Output:

```shell
Running step name=echo_hi
Hi, Zhang Wei
Running step name=echo_repeat
The echo_hi step said: Hi, Zhang Wei
```

## Produce a random value

Generates a random value for use in subsequent steps.
For full source code, see [random](https://gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/random).

Function definition:

```yaml
spec:
  outputs:
    random_value:
      type: string
---
exec:
  command:
    - ${{ func_dir }}/random
    - --output-file
    - ${{ output_file }}
```

Usage:

```yaml
my-job:
  image: gcr.io/distroless/static-debian12
  run:
    - name: random
      func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/random:1
    - name: print_random
      func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/echo:1
      inputs:
        message: "The random value is: ${{ steps.random.outputs.random_value }}"
```

Output:

```shell
Running step name=random
Running step name=print_random
The random value is: DVhV5vcd2BjDDtpV
```

## Extract fields from JSON

Runs `jq` to filter JSON input.
For full source code, see [jq](https://gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/jq).

Function definition:

```yaml
spec:
  inputs:
    filter:
      type: string
      default: "."
    input:
      type: string
      default: "{}"
    input_file:
      type: string
      default: ""
  outputs:
    result:
      type: struct
---
exec:
  command:
    - ${{ func_dir }}/jq-wrapper
    - --func-dir
    - ${{ func_dir }}
    - --filter
    - ${{ inputs.filter }}
    - --input
    - ${{ inputs.input }}
    - --input-file
    - ${{ inputs.input_file }}
    - --output-file
    - ${{ output_file }}
```

Usage:

```yaml
my-job:
  image: gcr.io/distroless/static-debian12
  run:
    - name: jq
      func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/jq:1
      inputs:
        input: |
          {"users":[
            {"name":"Alice","role":"admin"},
            {"name":"Bob","role":"viewer"},
            {"name":"Carol","role":"admin"}
          ]}
        filter: '[.users[] | select(.role == "admin") | .name]'
    - name: print_admins
      func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/echo:1
      inputs:
        message: "Admins: ${{ steps.jq.outputs.result.value }}"
```

Output:

```shell
Running step name=jq
Running step name=print_admins
Admins: ["Alice", "Carol"]
```

## Authenticate to Docker

Creates a Docker config and adds it as the value to the environment variable `DOCKER_AUTH_CONFIG`
for use in subsequent functions.
For full source code, see [Docker Auth](https://gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/docker-auth).

Function definition:

```yaml
spec:
  inputs:
    registry:
      type: string
      default: ""
      description: "registry URL"
    username:
      type: string
      default: ""
      description: "username for auth type"
    password:
      type: string
      default: ""
      description: "password for auth type"
    helper_name:
      type: string
      default: ""
      description: "credential helper name"
    store_name:
      type: string
      default: ""
      description: "default credential store name"
    config_file:
      type: string
      default: ""
      description: "path to existing config.json (default: ~/.docker/config.json)"
  outputs:
    auth:
      type: struct
---
env:
  DOCKER_PASSWORD: ${{ inputs.password }}
exec:
  work_dir: ${{ func_dir }}
  command:
    - ${{ func_dir }}/docker-auth
    - --registry
    - ${{ inputs.registry }}
    - --username
    - ${{ inputs.username }}
    - --helper-name
    - ${{ inputs.helper_name }}
    - --store-name
    - ${{ inputs.store_name }}
    - --config
    - ${{ inputs.config_file }}
    - --output-file
    - ${{ output_file }}
    - --export-file
    - ${{ export_file }}
```

Usage:

```yaml
build-image:
  image: gcr.io/distroless/static-debian12
  run:
    - name: auth_to_my_registry
      func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/docker-auth:1
      inputs:
        registry: my.registry.com
        username: ${{ vars.MY_REGISTRY_USER }}
        password: ${{ vars.MY_REGISTRY_PASSWORD }}
    - name: my_func
      func: my.registry.com/my-function:latest  # requires auth to fetch an image
```

Output:

```shell
Running step name=auth_to_my_registry
added basic auth for registry my.registry.com
docker auth configuration complete
Running step name=my_func
...
```
