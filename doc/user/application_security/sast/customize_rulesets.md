---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Customize rulesets
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Enabled](https://gitlab.com/gitlab-org/security-products/analyzers/ruleset/-/merge_requests/18) support for specifying ambiguous passthrough refs in GitLab 16.2.

You can customize the behavior of our SAST analyzers by [defining a ruleset configuration file](#create-the-configuration-file) in the
repository being scanned. There are two kinds of customization:

- Modifying the behavior of **predefined rules**. This includes:
  - [Disabling predefined rules](#disable-predefined-rules). Available for all analyzers.
  - [Overriding metadata of predefined rules](#override-metadata-of-predefined-rules). Available for all analyzers.
- Replacing predefined rules by [building a custom configuration](#build-a-custom-configuration)
  using **passthroughs**. Available only for the [Semgrep-based analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep).

GitLab Advanced SAST supports only modifying the behavior of **predefined rules**, not replacing predefined rules.

## Disable predefined rules

You can disable predefined rules for any SAST analyzer.

When you disable a rule:

- Most analyzers still scan for the vulnerability. The results are removed as a processing step after the scan completes, and they don't appear in the [`gl-sast-report.json` artifact](_index.md#download-a-sast-report).
- Findings for the disabled rule no longer appear in the [pipeline security tab](../vulnerability_report/pipeline.md).
- Existing findings for the disabled rule on the default branch are marked as [`No longer detected`](../vulnerability_report/_index.md#activity-filter) in the [vulnerability report](../vulnerability_report/_index.md).

The Semgrep-based analyzer handles disabled rules differently:

- To improve performance, the Semgrep-based analyzer doesn't scan for disabled rules at all.
- If you disable a rule in the Semgrep-based analyzer, existing vulnerability findings for that rule are [automatically resolved](_index.md#automatic-vulnerability-resolution) after you merge the `sast-ruleset.toml` file to the default branch.

See the [Schema](#schema) and [Examples](#examples) sections for information on how
to configure this behavior.

## Override metadata of predefined rules

You can override certain attributes of predefined rules for any SAST analyzer. This
can be useful when adapting SAST to your existing workflow or tools. For example, you
might want to override the severity of a vulnerability based on organizational policy,
or choose a different message to display in the Vulnerability Report.

See the [Schema](#schema) and [Examples](#examples) sections for information on how
to configure this behavior.

## Build a custom configuration

You can replace the [GitLab-maintained ruleset](rules.md) for the [Semgrep-based analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) with your own rules.

You provide your customizations via passthroughs, which are composed into a
passthrough chain at runtime and evaluated to produce a complete configuration. The
underlying scanner is then executed against this new configuration.

There are multiple passthrough types that let you provide configuration in different
ways, such as using a file committed to your repository or inline in the ruleset
configuration file. You can also choose how subsequent passthroughs in the chain are
handled; they can overwrite or append to previous configuration.

See the [Schema](#schema) and [Examples](#examples) sections for information on how
to configure this behavior.

## Create the configuration file

To create the ruleset configuration file:

1. Create a `.gitlab` directory at the root of your project, if one doesn't already exist.
1. Create a file named `sast-ruleset.toml` in the `.gitlab` directory.

## Specify a remote configuration file

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393452) in 16.1.

You can set a [CI/CD variable](../../../ci/variables/_index.md) to use a ruleset configuration file that's stored outside of the current repository.
This can help you apply the same rules across multiple projects.

The `SAST_RULESET_GIT_REFERENCE` variable uses a format similar to
[Git URLs](https://git-scm.com/docs/git-clone#_git_urls) for specifying a project URI,
optional authentication, and optional Git SHA. The variable uses the following format:

```plaintext
[<AUTH_USER>[:<AUTH_PASSWORD>]@]<PROJECT_PATH>[@<GIT_SHA>]
```

NOTE:
If a project has a `.gitlab/sast-ruleset.toml` file committed, that local configuration takes precedence and the file from `SAST_RULESET_GIT_REFERENCE` isn't used.

The following example [enables SAST](_index.md#configure-sast-in-your-cicd-yaml) and uses a shared ruleset customization file.
In this example, the file is committed on the default branch of `example-ruleset-project` at the path `.gitlab/sast-ruleset.toml`.

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  SAST_RULESET_GIT_REFERENCE: "gitlab.com/example-group/example-ruleset-project"
```

See [specify a private remote configuration example](#specify-a-private-remote-configuration) for advanced usage.

### Troubleshooting remote configuration files

If remote configuration file doesn't seem to be applying customizations correctly, the causes can be:

1. Your repository has a local `.gitlab/sast-ruleset.toml` file.
   - By default, a local file is used if it's present, even if a remote configuration is set as a variable.
   - You can set the [SECURE_ENABLE_LOCAL_CONFIGURATION CI/CD variable](../../../ci/variables/_index.md) to `false` to ignore the local configuration file.
1. There is a problem with authentication.
   - To check whether this is the cause of the problem, try referencing a configuration file from a repository location that doesn't require authentication.

## Schema

### The top-level section

The top-level section contains one or more _configuration sections_, defined as [TOML tables](https://toml.io/en/v1.0.0#table).

| Setting | Description |
| --------| ----------- |
| `[$analyzer]` | Declares a configuration section for an analyzer. The name follows the names defined in the list of [SAST analyzers](analyzers.md#official-analyzers). |

Configuration example:

```toml
[semgrep]
...
```

Avoid creating configuration sections that modify existing rules _and_ build a custom ruleset, as
the latter replaces predefined rules completely.

### The `[$analyzer]` configuration section

The `[$analyzer]` section lets you customize the behavior of an analyzer. Valid properties
differ based on the kind of configuration you're making.

| Setting | Applies to | Description |
| --------| -------------- | ----------- |
| `[[$analyzer.ruleset]]` | Predefined rules | Defines modifications to an existing rule. |
| `interpolate` | All | If set to `true`, you can use `$VAR` in the configuration to evaluate environment variables. Use this feature with caution, so you don't leak secrets or tokens. (Default: `false`) |
| `description` | Passthroughs | Description of the custom ruleset. |
| `targetdir`   | Passthroughs | The directory where the final configuration should be persisted. If empty, a directory with a random name is created. The directory can contain up to 100 MB of files. In case the SAST job is running with non-root user privileges, ensure that the [active user](../../../development/integrations/secure.md#permissions) has read and write permissions for this directory. |
| `validate`    | Passthroughs | If set to `true`, the content of each passthrough is validated. The validation works for `yaml`, `xml`, `json` and `toml` content. The proper validator is identified based on the extension used in the `target` parameter of the `[[$analyzer.passthrough]]` section. (Default: `false`) |
| `timeout`     | Passthroughs | The maximum time to spend to evaluate the passthrough chain, before timing out. The timeout cannot exceed 300 seconds. (Default: 60) |

#### `interpolate`

WARNING:
To reduce the risk of leaking secrets, use this feature with caution.

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

The `[[$analyzer.ruleset]]` section targets and modifies a single predefined rule. You can define
one to many of these sections per analyzer.

| Setting | Description |
| --------| ----------- |
| `disable` | Whether the rule should be disabled. (Default: `false`) |
| `[$analyzer.ruleset.identifier]` | Selects the predefined rule to be modified. |
| `[$analyzer.ruleset.override]` | Defines the overrides for the rule. |

Configuration example:

```toml
[semgrep]
  [[semgrep.ruleset]]
    disable = true
    ...
```

### The `[$analyzer.ruleset.identifier]` section

The `[$analyzer.ruleset.identifier]` section defines the identifiers of the predefined
rule that you wish to modify.

| Setting | Description |
| --------| ----------- |
| `type`  | The type of identifier used by the predefined rule. |
| `value` | The value of the identifier used by the predefined rule. |

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

The `[$analyzer.ruleset.override]` section allows you to override attributes of a predefined rule.

| Setting | Description |
| --------| ----------- |
| `description`  | A detailed description of the issue. |
| `message` | (Deprecated) A description of the issue. |
| `name` | The name of the rule. |
| `severity` | The severity of the rule. Valid options are: `Critical`, `High`, `Medium`, `Low`, `Unknown`, `Info`) |

NOTE:
While `message` is populated by the analyzers, it has been [deprecated](https://gitlab.com/gitlab-org/security-products/analyzers/report/-/blob/1d86d5f2e61dc38c775fb0490ee27a45eee4b8b3/vulnerability.go#L22)
in favor of `name` and `description`.

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

NOTE:
Passthrough configurations are available for the [Semgrep-based analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) only.

The `[[$analyzer.passthrough]]` section allows you to build a custom configuration for an analyzer. You
can define up to 20 of these sections per analyzer. Passthroughs are composed into a _passthrough chain_
that evaluates into a complete configuration that replaces the predefined rules of the analyzer.

Passthroughs are evaluated in order. Passthroughs listed later in the chain have
a higher precedence and can overwrite or append to data yielded by previous
passthroughs (depending on the `mode`). This is useful for cases where you need
to use or modify an existing configuration.

The size of the configuration generated by a single passthrough is limited to 10 MB.

| Setting | Applies to | Description |
| ------- | ---------- | ----------- |
| `type` | All |  One of `file`, `raw`, `git` or `url`. |
| `target` | All | The target file to contain the data written by the passthrough evaluation. If empty, a random filename is used. |
| `mode` | All | If `overwrite`, the `target` file is overwritten. If `append`, new content is appended to the `target` file. The `git` type only supports `overwrite`. (Default: `overwrite`) |
| `ref` | `type = "git"` | Contains the name of the branch, tag, or the SHA to pull |
| `subdir` | `type = "git"` | Used to select a subdirectory of the Git repository as the configuration source. |
| `value` | All | For the `file`, `url`, and `git` types, defines the location of the file or Git repository. For the `raw` type, contains the inline configuration. |
| `validator` | All | Used to explicitly invoke validators (`xml`, `yaml`, `json`, `toml`) on the target file after the evaluation of a passthrough. |

#### Passthrough types

| Type   | Description |
| ------ | ----------- |
| `file` | Use a file that is present in the Git repository. |
| `raw`  | Provide the configuration inline. |
| `git`  | Pull the configuration from a remote Git repository. |
| `url`  | Fetch the configuration using HTTP. |

WARNING:
When using the `raw` passthrough with a YAML snippet, it's recommended to format all indentation
in the `sast-ruleset.toml` file as spaces. The YAML specification mandates spaces over tabs, and the
analyzer fails to parse your custom ruleset unless the indentation is represented accordingly.

## Examples

### Disable predefined GitLab Advanced SAST rules

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

### Disable predefined rules of other SAST analyzers

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

### Override predefined rule metadata

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

### Build a custom configuration using a file passthrough for `semgrep`

With the following custom ruleset configuration, the predefined ruleset
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

With the following custom ruleset configuration, the predefined ruleset
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
initialising the top-level `rules` object, according to the
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

The following example [enables SAST](_index.md#configure-sast-in-your-cicd-yaml) and uses a shared ruleset customization file. The file is:

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
