---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Configure flow execution
---

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/477166) in GitLab 18.3.

{{< /history >}}

Flows use agents to execute tasks.

- Flows executed from the GitLab UI use CI/CD.
- Flows executed in an IDE run locally.

## Configure CI/CD execution

You can customize how flows are executed in CI/CD by creating an agent configuration file in your project.

### Create the configuration file

1. In your project's repository, create a `.gitlab/duo/` folder if it doesn't exist.
1. In the folder, create a configuration file named `agent-config.yml`.
1. Add your desired configuration options (see sections below).
1. Commit and push the file to your default branch.

The configuration is applied when flows run in CI/CD for your project.

### Change the default Docker image

By default, all flows executed with CI/CD use a standard Docker image provided by GitLab.
However, you can change the Docker image and specify your own instead.
Your own image can be useful for complex projects that require specific dependencies or tools.

To change the default Docker image, add the following to your `agent-config.yml` file:

```yaml
image: YOUR_DOCKER_IMAGE
```

For example:

```yaml
image: python:3.11-slim
```

Or for a Node.js project:

```yaml
image: node:20-alpine
```

#### Custom image requirements

If you use a custom Docker image, ensure that the following commands are available for the agent to function correctly:

- `git`
- `wget`
- `tar`
- `chmod`

Most base images include these commands by default. However, minimal images (like `alpine` variants)
might require you to install them explicitly. If needed, you can install missing commands in the
[setup script configuration](#configure-setup-scripts).

Additionally, depending on the tool calls made by agents during flow execution, other common utilities may be required.

For example, if you use an Alpine-based image:

```yaml
image: python:3.11-alpine
setup_script:
  - apk add --no-cache git wget tar bash
```

### Configure setup scripts

You can define setup scripts that run before your flow executes. This is useful for installing dependencies, configuring environments, or performing any necessary initialization.

To add setup scripts, add the following to your `agent-config.yml` file:

```yaml
setup_script:
  - apt-get update && apt-get install -y curl
  - pip install -r requirements.txt
  - echo "Setup complete"
```

These commands:

- Run before the main workflow commands.
- Execute in the order specified.
- Can be a single command or an array of commands.

### Configure caching

You can configure caching to speed up subsequent flow runs by preserving files and directories between executions. Caching can be useful for dependency folders like `node_modules` or Python virtual environments.

#### Basic cache configuration

To cache specific paths, add the following to your `agent-config.yml` file:

```yaml
cache:
  paths:
    - node_modules/
    - .npm/
```

#### Cache with keys

You can use cache keys to create different caches for different scenarios. Cache keys help ensure that the cache is based on your project's state.

##### Use a string key

```yaml
cache:
  key: my-project-cache
  paths:
    - vendor/
    - .bundle/
```

##### Use file-based cache keys

Create dynamic cache keys based on file contents (like lock files). When these files change, a new cache is created. This generates a SHA checksum of the specified files:

```yaml
cache:
  key:
    files:
      - package-lock.json
      - yarn.lock
  paths:
    - node_modules/
```

##### Use a prefix with file-based keys

Combine a prefix with the SHA computed for the cache key files:

```yaml
cache:
  key:
    files:
      - package-lock.json
    prefix: $CI_JOB_NAME
  paths:
    - node_modules/
    - .npm/
```

In this example, if the job name is `test` and the SHA checksum is `abc123`, the cache key becomes `test-abc123`.

#### Cache limitations

- You can specify up to two files for cache key generation. If more files are specified, only the first two are used.
- The cache `paths` field is required. A cache configuration without paths has no effect.
- Cache keys support CI/CD variables in the `prefix` field.

### Complete configuration example

Here's an example `agent-config.yml` file that uses all available options:

```yaml
# Custom Docker image
image: python:3.11

# Setup script to run before the flow
setup_script:
  - apt-get update && apt-get install -y build-essential
  - pip install --upgrade pip
  - pip install -r requirements.txt

# Cache configuration
cache:
  key:
    files:
      - requirements.txt
      - Pipfile.lock
    prefix: python-deps
  paths:
    - .cache/pip
    - venv/
```

This configuration:

- Uses Python 3.11 as the base image.
- Installs build tools and Python dependencies before running the flow.
- Caches pip and virtual environment directories.
- Creates a new cache when `requirements.txt` or `Pipfile.lock` changes, with a prefix of `python-deps`.
