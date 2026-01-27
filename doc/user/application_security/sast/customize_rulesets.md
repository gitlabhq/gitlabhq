---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Customize SAST analyzer rules in GitLab by disabling, overriding, or replacing default rules.
title: Customize rulesets
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Enabled](https://gitlab.com/gitlab-org/security-products/analyzers/ruleset/-/merge_requests/18) support for specifying ambiguous passthrough refs in GitLab 16.2.

{{< /history >}}

Each SAST analyzer supports different levels of customization through the ruleset configuration
file. The Semgrep-based SAST analyzer and GitLab Advanced SAST analyzer have a
[default ruleset](rules.md).

## Ruleset glossary

Rule
: An individual security check or detection pattern that scans for specific vulnerabilities.

Ruleset
: A collection of rules and their configuration, defined in the `sast-ruleset.toml` file.

Passthrough

: A passthrough is a configuration source that pulls ruleset customizations from a file, Git
repository, URL, or inline configuration. You can combine multiple passthroughs into a chain, where
each one can overwrite or append to the previous configuration.

## Rule customization options

SAST rulesets come with default rules, but every organization has different security requirements.
You can customize these rulesets by disabling rules, overriding their metadata, or replacing or
adding rules.

The table below shows which customization options are available for each analyzer type.

| Customization                          | GitLab Advanced SAST                                                                                                                                             | GitLab Semgrep             | [Other analyzers](analyzers.md#official-analyzers) |
|----------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------|----------------------------------------------------|
| Disable default rules               | {{< yes >}}                                                                                                                                                      | {{< yes >}}                | {{< yes >}}                                        |
| Override metadata of default rules  | {{< yes >}}                                                                                                                                                      | {{< yes >}}                | {{< yes >}}                                        |
| Replace or add to default rules | Supports modifying the behavior of default non-taint, structural rules and the application of file and raw passthroughs. Other passthrough types are ignored. | Supports full passthroughs. | {{< no >}}                                         |

### Disable default rules

You can disable default rules for any SAST analyzer. For example, you might want to exclude a
specific rule based on organizational policy.

See the following examples:

- [Disable default GitLab Advanced SAST rules](#disable-default-gitlab-advanced-sast-rules)
- [Disable default rules of other SAST analyzers](#disable-default-rules-of-other-sast-analyzers)

### Override metadata of default rules

You can override certain attributes of default rules for any SAST analyzer. For example, you
might want to override the severity of a vulnerability based on organizational policy, or choose a
different message to display in the vulnerability report.

See [override default rule metadata](#override-default-rule-metadata) for an example.

### Replace or add to the default rules

You can replace or add to the default rules of the Semgrep-based SAST analyzer and GitLab Advanced
SAST analyzer. By default, defining a custom ruleset replaces the default ruleset. To add to the
default ruleset you must set `keepdefaultrules` to `true` in your
[ruleset configuration file](#configuration-methods).

See the following examples:

- [Replace the default rules of GitLab Advanced SAST](#replace-the-default-rules-of-gitlab-advanced-sast)
- [Replace or add to the default rules of `semgrep`](#replace-or-add-to-the-default-rules-of-semgrep)

### Effects of ruleset customization

The following table describes what happens when you customize SAST rulesets:

| Action                     | Scan behavior                                                                                                                                                               | Pipeline security tab                                                                                                      | Vulnerability report                                                                                                                                   |
|----------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------|
| Disable a rule             | Analyzers still scan for the vulnerability but the rule's results are removed after the scan completes. GitLab Advanced SAST excludes disabled rules from the initial scan. | Findings detected by the rule before it was disabled no longer appear after the next pipeline runs.                        | Vulnerabilities detected by the rule before it was disabled are marked as [**No longer detected**](../vulnerability_report/_index.md#activity-filter). |
| Override metadata          | No change to scan behavior.                                                                                                                                                 | Metadata of findings detected by the rule before it was overridden are updated after the next pipeline runs.               | Metadata of vulnerabilities detected by the rule before it was overridden are updated.                                                                 |
| Replace default ruleset | The default ruleset is not used by analyzers that support custom rulesets.                                                                                               | Findings detected by rules in the default ruleset before it was replaced no longer appear after the next pipeline runs. | Vulnerabilities detected by rules in the default ruleset are marked as [**No longer detected**](../vulnerability_report/_index.md#activity-filter). |

## Configuration methods

You can provide your ruleset customizations in the following ways:

Local ruleset file
: Define your customizations in a `sast-ruleset.toml` file committed to your
  repository. This approach keeps your ruleset configuration under version control alongside your
  code.

Remote ruleset file
: Specify a remote location (Git repository, URL, or other source) where your
  ruleset configuration is hosted. This approach lets you manage rulesets centrally and reuse them
  across multiple projects.

> [!note]
> A local `.gitlab/sast-ruleset.toml` file takes precedence over a remote ruleset file.

You provide your customizations by using passthroughs, which are configuration sources that can be
combined into a ruleset.

All ruleset customization must comply with the [SAST ruleset schema](#schema).

### Local ruleset file

To create the local ruleset configuration file:

1. Create a `.gitlab` directory at the root of your project, if one doesn't already exist.
1. Create a file named `sast-ruleset.toml` in the `.gitlab` directory.
1. Add your custom ruleset to the `sast-ruleset.toml` file.
1. Commit the local ruleset configuration file to the repository.

For examples of a local ruleset file, see [examples](#examples).

### Remote ruleset file

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393452) in 16.1.

{{< /history >}}

You can set a [CI/CD variable](../../../ci/variables/_index.md) to use a ruleset configuration file
that's stored outside of the current repository. This can help you apply the same rules across
multiple projects.

The `SAST_RULESET_GIT_REFERENCE` variable uses a format similar to
[Git URLs](https://git-scm.com/docs/git-clone#_git_urls) for specifying a project URI,
optional authentication, and optional Git SHA. The variable uses the following format:

```plaintext
[<AUTH_USER>[:<AUTH_PASSWORD>]@]<PROJECT_PATH>[@<GIT_SHA>]
```

> [!note]
> A local `.gitlab/sast-ruleset.toml` file takes precedence over a remote ruleset file.

The following example enables SAST and uses a shared ruleset customization file. In this example,
the file is committed on the default branch of `example-ruleset-project` at the path
`.gitlab/sast-ruleset.toml`.

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  SAST_RULESET_GIT_REFERENCE: "gitlab.com/example-group/example-ruleset-project"
```

For an advanced example, see
[specify a private remote configuration example](#specify-a-private-remote-configuration).

#### Troubleshooting remote configuration files

If remote configuration file doesn't seem to be applying customizations correctly, the causes can be:

1. Your repository has a local `.gitlab/sast-ruleset.toml` file.
   - By default, a local file is used if it's present, even if a remote configuration is set as a variable.
   - You can set the [SECURE_ENABLE_LOCAL_CONFIGURATION CI/CD variable](../../../ci/variables/_index.md) to `false` to ignore the local configuration file.
1. There is a problem with authentication.
   - To check whether this is the cause of the problem, try referencing a configuration file from a repository location that doesn't require authentication.

## Schema

The ruleset configuration file uses TOML syntax. The following sections describe the structure and
valid settings for each configuration element.

### The top-level section

The top-level section contains one or more configuration sections, defined as [TOML tables](https://toml.io/en/v1.0.0#table).

| Setting       | Description                                                                                                                                            |
|---------------|--------------------------------------------------------------------------------------------------------------------------------------------------------|
| `[$analyzer]` | Declares a configuration section for an analyzer. The name follows the names defined in the list of [SAST analyzers](analyzers.md#official-analyzers). |

Configuration example:

```toml
[semgrep]
...
```

Avoid creating configuration sections that modify existing rules and build a custom ruleset, as
the latter replaces default rules completely.

### The `[$analyzer]` configuration section

The `[$analyzer]` section lets you customize the behavior of an analyzer. Valid properties
differ based on the kind of configuration you're making.

| Setting                 | Applies to    | Description                                                                                                                                                                                                                                                                                                   |
|-------------------------|---------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `[[$analyzer.ruleset]]` | Default rules | Defines modifications to an existing rule.                                                                                                                                                                                                                                                                    |
| `interpolate`           | All           | If set to `true`, you can use `$VAR` in the configuration to evaluate environment variables. Use this feature with caution, so you don't leak secrets or tokens. (Default: `false`)                                                                                                                           |
| `description`           | Passthroughs  | Description of the custom ruleset.                                                                                                                                                                                                                                                                            |
| `targetdir`             | Passthroughs  | The directory where the final configuration should be persisted. If empty, a directory with a random name is created. The directory can contain up to 100 MB of files. In case the SAST job is running with non-root user privileges, ensure that the user has read and write permissions for this directory. |
| `validate`              | Passthroughs  | If set to `true`, the content of each passthrough is validated. The validation works for `yaml`, `xml`, `json` and `toml` content. The proper validator is identified based on the extension used in the `target` parameter of the `[[$analyzer.passthrough]]` section. (Default: `false`)                    |
| `timeout`               | Passthroughs  | The maximum time to spend to evaluate the passthrough chain, before timing out. The timeout cannot exceed 300 seconds. (Default: 60)                                                                                                                                                                          |
| `keepdefaultrules`      | Passthroughs  | If set to `true`, the analyzer's default rules are activated in conjunction with the defined passthroughs. (Default: `false`)                                                                                                                                                                                 |

#### `interpolate`

> [!warning]
> To reduce the risk of leaking secrets, use this feature with caution.

The example below shows a configuration that uses the `$GITURL` environment variable to access a
private repository. The variable contains a username and token (for example `https://user:token@url`), so
they're not explicitly stored in the configuration file.

```toml
[semgrep]
  description = "My private Semgrep ruleset"
  interpolate = true

  [[semgrep.passthrough]]
    type  = "git"
    value = "$GITURL"
    ref = "main"
```

### The `[[$analyzer.ruleset]]` section

The `[[$analyzer.ruleset]]` section targets and modifies a single default rule. You can define
one to many of these sections per analyzer.

| Setting                          | Description                                             |
|----------------------------------|---------------------------------------------------------|
| `disable`                        | Whether the rule should be disabled. (Default: `false`) |
| `[$analyzer.ruleset.identifier]` | Selects the default rule to be modified.                |
| `[$analyzer.ruleset.override]`   | Defines the overrides for the rule.                     |

Configuration example:

```toml
[semgrep]
  [[semgrep.ruleset]]
    disable = true
    ...
```

### The `[$analyzer.ruleset.identifier]` section

The `[$analyzer.ruleset.identifier]` section defines the identifiers of the default
rule that you wish to modify.

| Setting | Description                                           |
|---------|-------------------------------------------------------|
| `type`  | The type of identifier used by the default rule.      |
| `value` | The value of the identifier used by the default rule. |

You can look up the correct values for `type` and `value` by viewing the
[`gl-sast-report.json`](_index.md#download-a-sast-report) produced by the analyzer.
You can download this file as a job artifact from the analyzer's CI job.

For example, the snippet below shows a finding from a `semgrep` rule with three
identifiers. The `type` and `value` keys in the JSON object correspond to the
values you should provide in this section.

```json
...
  "vulnerabilities": [
    {
      "id": "7331a4b7093875f6eb9f6eb1755b30cc792e9fb3a08c9ce673fb0d2207d7c9c9",
      "category": "sast",
      "message": "Key Exchange without Entity Authentication",
      "description": "Audit the use of ssh.InsecureIgnoreHostKey\n",
      ...
      "identifiers": [
        {
          "type": "semgrep_id",
          "name": "gosec.G106-1",
          "value": "gosec.G106-1"
        },
        {
          "type": "cwe",
          "name": "CWE-322",
          "value": "322",
          "url": "https://cwe.mitre.org/data/definitions/322.html"
        },
        {
          "type": "gosec_rule_id",
          "name": "Gosec Rule ID G106",
          "value": "G106"
        }
      ]
    }
    ...
  ]
...
```

Configuration example:

```toml
[semgrep]
  [[semgrep.ruleset]]
    [semgrep.ruleset.identifier]
      type = "semgrep_id"
      value = "gosec.G106-1
    ...
```

### The `[$analyzer.ruleset.override]` section

The `[$analyzer.ruleset.override]` section allows you to override attributes of a default rule.

| Setting       | Description                                                                                         |
|---------------|-----------------------------------------------------------------------------------------------------|
| `description` | A detailed description of the issue.                                                                |
| `message`     | (Deprecated) A description of the issue.                                                            |
| `name`        | The name of the rule.                                                                               |
| `severity`    | The severity of the rule. Valid options are: `Critical`, `High`, `Medium`, `Low`, `Unknown`, `Info` |

> [!note]
> While `message` is populated by the analyzers, it has been [deprecated](https://gitlab.com/gitlab-org/security-products/analyzers/report/-/blob/1d86d5f2e61dc38c775fb0490ee27a45eee4b8b3/vulnerability.go#L22)
> in favor of `name` and `description`.

Configuration example:

```toml
[semgrep]
  [[semgrep.ruleset]]
    [semgrep.ruleset.override]
      severity = "Critical"
      name = "Command injection"
    ...
```

### The `[[$analyzer.passthrough]]` section

> [!note]
> Passthrough configurations are available for the [Semgrep-based analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) only.

The `[[$analyzer.passthrough]]` section allows you to build a custom configuration for an analyzer. You
can define up to 20 of these sections per analyzer. Passthroughs are composed into a _passthrough chain_
that evaluates into a complete configuration that replaces the default rules of the analyzer.

Passthroughs are evaluated in order. Passthroughs listed later in the chain have
a higher precedence and can overwrite or append to data yielded by previous
passthroughs (depending on the `mode`). This is useful for cases where you need
to use or modify an existing configuration.

The size of the configuration generated by a single passthrough is limited to 10 MB.

| Setting     | Applies to     | Description                                                                                                                                                                   |
|-------------|----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `type`      | All            | One of `file`, `raw`, `git` or `url`.                                                                                                                                         |
| `target`    | All            | The target file to contain the data written by the passthrough evaluation. If empty, a random filename is used.                                                               |
| `mode`      | All            | If `overwrite`, the `target` file is overwritten. If `append`, new content is appended to the `target` file. The `git` type only supports `overwrite`. (Default: `overwrite`) |
| `ref`       | `type = "git"` | Contains the name of the branch, tag, or the SHA to pull                                                                                                                      |
| `subdir`    | `type = "git"` | Used to select a subdirectory of the Git repository as the configuration source.                                                                                              |
| `value`     | All            | For the `file`, `url`, and `git` types, defines the location of the file or Git repository. For the `raw` type, contains the inline configuration.                            |
| `validator` | All            | Used to explicitly invoke validators (`xml`, `yaml`, `json`, `toml`) on the target file after the evaluation of a passthrough.                                                |

#### Passthrough types

| Type   | Description                                          |
|--------|------------------------------------------------------|
| `file` | Use a file that is present in the Git repository.    |
| `raw`  | Provide the configuration inline.                    |
| `git`  | Pull the configuration from a remote Git repository. |
| `url`  | Fetch the configuration using HTTP.                  |

> [!warning]
> When using the `raw` passthrough with a YAML snippet, it's recommended to format all indentation
> in the `sast-ruleset.toml` file as spaces. The YAML specification mandates spaces over tabs, and the
> analyzer fails to parse your custom ruleset unless the indentation is represented accordingly.

## Examples

The following examples show how to customize rulesets for common scenarios. Use the schema section
to understand the configuration options used in each example.

### Replace the default rules of GitLab Advanced SAST

With the following custom ruleset configuration, the default ruleset
of the GitLab Advanced SAST analyzer is replaced with a custom ruleset contained in
a file called `my-gitlab-advanced-sast-rules.yaml` in the repository being scanned.

```yaml
# my-gitlab-advanced-sast-rules.yaml
---
rules:
- id: my-custom-rule
  pattern: print("Hello World")
  message: |
    Unauthorized use of Hello World.
  severity: ERROR
  languages:
  - python
```

```toml
[gitlab-advanced-sast]
  description = "My custom ruleset for Semgrep"

  [[gitlab-advanced-sast.passthrough]]
    type  = "file"
    value = "my-gitlab-advanced-sast-rules.yaml"
```

### Disable default GitLab Advanced SAST rules

You can disable GitLab Advanced SAST rules or edit their metadata.
The following example disables rules based on different criteria:

- A CWE identifier, which identifies an entire class of vulnerabilities.
- An GitLab Advanced SAST rule ID, which identifies a specific detection strategy used in GitLab Advanced SAST.
- An associated Semgrep rule ID, which is included in GitLab Advanced SAST findings for compatibility. This additional metadata allows findings to be automatically transitioned when both analyzers create similar findings in the same location.

These identifiers are shown in the [vulnerability details](../vulnerabilities/_index.md) of each vulnerability.
You can also see each identifier and its associated `type` in the [downloadable SAST report artifact](_index.md#download-a-sast-report).

```toml
[gitlab-advanced-sast]
  [[gitlab-advanced-sast.ruleset]]
    disable = true
    [gitlab-advanced-sast.ruleset.identifier]
      type = "cwe"
      value = "89"

  [[gitlab-advanced-sast.ruleset]]
    disable = true
    [gitlab-advanced-sast.ruleset.identifier]
      type = "gitlab-advanced-sast_id"
      value = "java-spring-csrf-unrestricted-requestmapping-atomic"

  [[gitlab-advanced-sast.ruleset]]
    disable = true
    [gitlab-advanced-sast.ruleset.identifier]
      type = "semgrep_id"
      value = "java_cookie_rule-CookieHTTPOnly"
```

### Disable default rules of other SAST analyzers

With the following custom ruleset configuration, the following rules are omitted from the report:

- `semgrep` rules with a `semgrep_id` of `gosec.G106-1` or a `cwe` of `322`.
- `sobelow` rules with a `sobelow_rule_id` of `sql_injection`.
- `flawfinder` rules with a `flawfinder_func_name` of `memcpy`.

```toml
[semgrep]
  [[semgrep.ruleset]]
    disable = true
    [semgrep.ruleset.identifier]
      type = "semgrep_id"
      value = "gosec.G106-1"

  [[semgrep.ruleset]]
    disable = true
    [semgrep.ruleset.identifier]
      type = "cwe"
      value = "322"

[sobelow]
  [[sobelow.ruleset]]
    disable = true
    [sobelow.ruleset.identifier]
      type = "sobelow_rule_id"
      value = "sql_injection"

[flawfinder]
  [[flawfinder.ruleset]]
    disable = true
    [flawfinder.ruleset.identifier]
      type = "flawfinder_func_name"
      value = "memcpy"
```

### Override default rule metadata

With the following custom ruleset configuration, vulnerabilities found with
`semgrep` with a type `CWE` and a value `322` have their severity overridden to `Critical`.

```toml
[semgrep]
  [[semgrep.ruleset]]
    [semgrep.ruleset.identifier]
      type = "cwe"
      value = "322"
    [semgrep.ruleset.override]
      severity = "Critical"
```

### Replace or add to the default rules of `semgrep`

With the following custom ruleset configuration, the default ruleset
of the `semgrep` analyzer is replaced with a custom ruleset contained in
a file called `my-semgrep-rules.yaml` in the repository being scanned.

```yaml
# my-semgrep-rules.yml
---
rules:
- id: my-custom-rule
  pattern: print("Hello World")
  message: |
    Unauthorized use of Hello World.
  severity: ERROR
  languages:
  - python
```

```toml
[semgrep]
  description = "My custom ruleset for Semgrep"

  [[semgrep.passthrough]]
    type  = "file"
    value = "my-semgrep-rules.yml"
```

### Build a custom configuration using a passthrough chain for `semgrep`

With the following custom ruleset configuration, the default ruleset
of the `semgrep` analyzer is replaced with a custom ruleset produced by
evaluating a chain of four passthroughs. Each passthrough produces a file
that's written to the `/sgrules` directory within the container. A
`timeout` of 60 seconds is set in case any Git remotes are unresponsive.

Different passthrough types are demonstrated in this example:

- Two `git` passthroughs, the first pulling `develop` branch from the
  `myrules` Git repository, and the second pulling revision `97f7686`
  from the `sast-rules` repository, and considering only files in the
  `go` subdirectory.
  - The `sast-rules` entry has a higher precedence because it appears later in
    the configuration.
  - If there's a filename collision between the two checkouts, files
    from the `sast-rules` repository overwrite files from the
    `myrules` repository.
- A `raw` passthrough, which writes its `value` to `/sgrules/insecure.yml`.
- A `url` passthrough, which fetches a configuration hosted at a URL and
  writes it to `/sgrules/gosec.yml`.

Afterwards, Semgrep is invoked with the final configuration located under
`/sgrules`.

```toml
[semgrep]
  description = "My custom ruleset for Semgrep"
  targetdir = "/sgrules"
  timeout = 60

  [[semgrep.passthrough]]
    type  = "git"
    value = "https://gitlab.com/user/myrules.git"
    ref = "develop"

  [[semgrep.passthrough]]
    type  = "git"
    value = "https://gitlab.com/gitlab-org/secure/gsoc-sast-vulnerability-rules/playground/sast-rules.git"
    ref = "97f7686db058e2141c0806a477c1e04835c4f395"
    subdir = "go"

  [[semgrep.passthrough]]
    type  = "raw"
    target = "insecure.yml"
    value = """
rules:
- id: "insecure"
  patterns:
    - pattern: "func insecure() {...}"
  message: |
    Insecure function insecure detected
  metadata:
    cwe: "CWE-200: Exposure of Sensitive Information to an Unauthorized Actor"
  severity: "ERROR"
  languages:
    - "go"
"""

  [[semgrep.passthrough]]
    type  = "url"
    value = "https://semgrep.dev/c/p/gosec"
    target = "gosec.yml"
```

### Configure the mode for passthroughs in a chain

You can choose how to handle filename conflicts that occur between
passthroughs in a chain. The default behavior is to overwrite
existing files with the same name, but you can choose `mode = append`
instead to append the content of later files onto earlier ones.

You can use the `append` mode for the `file`, `url`, and `raw`
passthrough types only.

With the following custom ruleset configuration, two `raw` passthroughs
are used to iteratively assemble the `/sgrules/my-rules.yml` file, which
is then provided to Semgrep as the ruleset. Each passthrough appends a
single rule to the ruleset. The first passthrough is responsible for
initializing the top-level `rules` object, according to the
[Semgrep rule syntax](https://semgrep.dev/docs/writing-rules/rule-syntax).

```toml
[semgrep]
  description = "My custom ruleset for Semgrep"
  targetdir = "/sgrules"
  validate = true

  [[semgrep.passthrough]]
    type  = "raw"
    target = "my-rules.yml"
    value = """
rules:
- id: "insecure"
  patterns:
    - pattern: "func insecure() {...}"
  message: |
    Insecure function 'insecure' detected
  metadata:
    cwe: "..."
  severity: "ERROR"
  languages:
    - "go"
"""

  [[semgrep.passthrough]]
    type  = "raw"
    mode  = "append"
    target = "my-rules.yml"
    value = """
- id: "secret"
  patterns:
    - pattern-either:
        - pattern: '$MASK = "..."'
    - metavariable-regex:
        metavariable: "$MASK"
        regex: "(password|pass|passwd|pwd|secret|token)"
  message: |
    Use of hard-coded password
  metadata:
    cwe: "..."
  severity: "ERROR"
  languages:
    - "go"
"""
```

```yaml
# /sgrules/my-rules.yml
rules:
- id: "insecure"
  patterns:
    - pattern: "func insecure() {...}"
  message: |
    Insecure function 'insecure' detected
  metadata:
    cwe: "..."
  severity: "ERROR"
  languages:
    - "go"
- id: "secret"
  patterns:
    - pattern-either:
        - pattern: '$MASK = "..."'
    - metavariable-regex:
        metavariable: "$MASK"
        regex: "(password|pass|passwd|pwd|secret|token)"
  message: |
    Use of hard-coded password
  metadata:
    cwe: "..."
  severity: "ERROR"
  languages:
    - "go"
```

### Specify a private remote configuration

The following example enables SAST and uses a shared ruleset customization file. The file is:

- Downloaded from a private project that requires authentication, by using a [Group Access Token](../../group/settings/group_access_tokens.md) securely stored within a CI variable.
- Checked out at a specific Git commit SHA instead of the default branch.

See [group access tokens](../../group/settings/group_access_tokens.md#bot-users-for-groups) for how to find the username associated with a group token.

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  SAST_RULESET_GIT_REFERENCE: "group_2504721_bot_7c9311ffb83f2850e794d478ccee36f5:$PERSONAL_ACCESS_TOKEN@gitlab.com/example-group/example-ruleset-project@c8ea7e3ff126987fb4819cc35f2310755511c2ab"
```

### Demo Projects

There are [demonstration projects](https://gitlab.com/gitlab-org/security-products/demos/SAST-analyzer-configurations) that illustrate some of these configuration options.

Many of these projects illustrate using remote rulesets to override or disable rules and are grouped together by which analyzer they are for.

There are also some video demonstrations walking through setting up remote rulesets:

- [IaC analyzer with a remote ruleset](https://youtu.be/VzJFyaKpA-8)
