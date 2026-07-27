---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Reference for the supported keys in the agent configuration file that configures how flows execute in CI/CD.
title: Agent configuration file syntax
---

{{< details >}}

- Tier: [Free](../../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

The `agent-config.yml` file configures how flows execute in CI/CD for your project.
Place the file at `.gitlab/duo/agent-config.yml` in your project repository.

For more information about usage, see [Configure flow execution](_index.md).

> [!note]
> The configuration file is read-only from the project's default branch.
> Files committed to other branches are ignored, even when a flow runs from those branches.

## Supported keys

| Key | Type | Description |
|-----|------|-------------|
| `image` | string | Docker image to use for flow execution. Minimum 1 character, maximum 512 characters. |
| `setup_script` | string or array of strings | Shell commands to run before the flow starts. |
| `network_policy` | object | Network access rules for the execution environment. For more information, see [Configure a network policy](../../environment_sandbox.md#configure-a-network-policy). |
| `network_policy.allowed_domains` | array of strings | Domains the flow can access. Maximum 1000 entries. |
| `network_policy.denied_domains` | array of strings | Domains the flow cannot access. Maximum 1000 entries. |
| `network_policy.include_recommended_allowed` | boolean | Include GitLab recommended allowed domains. Default: `false`. |
| `network_policy.allow_all_unix_sockets` | boolean | Allow all Unix socket connections. Default: `false`. |
| `cache` | object | Files and directories to preserve between flow runs. For more information, see [Configure caching](_index.md#configure-caching). |
| `cache.paths` | string or array of strings | Paths to cache. Required for caching to take effect. |
| `cache.key` | string or object | Cache key. If omitted, a default key is used. |
| `cache.key.files` | array of strings | Files used to generate a SHA-based cache key. Maximum 2 files. |
| `cache.key.prefix` | string | Prefix combined with the file SHA to form the cache key. Requires `files`. |

## Complete example

The following example uses all available configuration options:

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

# Network configuration
network_policy:
  include_recommended_allowed: true
  allow_all_unix_sockets: true
  allowed_domains:
    - my-own-site.com
  denied_domains:
    - malicious.com
```
