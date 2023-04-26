---
stage: Secure
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Customize rulesets **(ULTIMATE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/235382) in GitLab 13.5.
> - [Added](https://gitlab.com/gitlab-org/gitlab/-/issues/339614) support for
>   passthrough chains. Expanded to include additional passthrough types of `file`, `git`, and `url` in GitLab 14.6.
> - [Added](https://gitlab.com/gitlab-org/gitlab/-/issues/235359) support for overriding rules in GitLab 14.8.

You can customize the behavior of our SAST analyzers by [defining a ruleset configuration file](#create-the-configuration-file) in the
repository being scanned. There are two kinds of customization:

- Modifying the behavior of **predefined rules**. This includes:
  - [Disabling predefined rules](#disable-predefined-rules). Available for all analyzers.
  - [Overriding predefined rules](#override-predefined-rules). Available for all analyzers.
- Replacing predefined rules by [synthesizing a custom configuration](#synthesize-a-custom-configuration)
  using **passthroughs**. Available for only [nodejs-scan](https://gitlab.com/gitlab-org/security-products/analyzers/nodejs-scan)
  and [semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep).

## Disable predefined rules

You can disable predefined rules for any SAST analyzer.

When you disable a rule:

- Most analyzers still scan for the vulnerability. The results are removed as a processing step after the scan completes, and they don't appear in the [`gl-sast-report.json` artifact](index.md#reports-json-format).
- Findings for the disabled rule no longer appear in the [Pipeline Security tab](../index.md#view-security-scan-information-in-the-pipeline-security-tab).
- Existing findings for the disabled rule on the default branch are marked ["No longer detected"](../vulnerability_report/index.md#activity-filter) in the [Vulnerability Report](../index.md#view-security-scan-information-in-the-vulnerability-report).

The Semgrep-based analyzer handles disabled rules differently:

- To improve performance, the Semgrep-based analyzer doesn't scan for disabled rules at all.
- If you disable a rule in the Semgrep-based analyzer, existing vulnerability findings for that rule are [automatically resolved](index.md#automatic-vulnerability-resolution) after you merge the `sast-ruleset.toml` file to the default branch.

See the [Schema](#schema) and [Examples](#examples) sections for information on how
to configure this behavior.

## Override predefined rules

Certain attributes of predefined rules can be overridden for any SAST analyzer. This
can be useful when adapting SAST to your existing workflow or tools. For example, you
might want to override the severity of a vulnerability based on organizational policy,
or choose a different message to display in the Vulnerability Report.

See the [Schema](#schema) and [Examples](#examples) sections for information on how
to configure this behavior.

## Synthesize a custom configuration

You can completely replace the predefined rules of some SAST analyzers:

- [nodejs-scan](https://gitlab.com/gitlab-org/security-products/analyzers/nodejs-scan) - you
  can replace the default [njsscan configuration file](https://github.com/ajinabraham/njsscan#configure-njsscan)
  with your own.
- [semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) - you can replace
  the [GitLab-maintained ruleset](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/tree/main/rules)
  with your own.

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

## Schema

### The top-level section

The top-level section contains one or more _configuration sections_, defined as [TOML tables](https://toml.io/en/v1.0.0#table).

| Setting | Description |
| --------| ----------- |
| `[$analyzer]` | Declares a configuration section for an analyzer. The name follows the snake-case names defined in the list of [SAST analyzers](analyzers.md#sast-analyzers). |

Configuration example:

```toml
[semgrep]
...
```

Avoid creating configuration sections that modify existing rules _and_ synthesize a custom ruleset, as
the latter replaces predefined rules completely.

### The `[$analyzer]` configuration section

The `[$analyzer]` section lets you customize the behavior of an analyzer. Valid properties
differ based on the kind of configuration you're making.

| Setting | Applies to | Description |
| --------| -------------- | ----------- |
| `[[$analyzer.ruleset]]` | Predefined rules | Defines modifications to an existing rule. |
| `interpolate` | All | If set to `true`, you can use `$VAR` in the configuration to evaluate environment variables. Use this feature with caution, so you don't leak secrets or tokens. (Default: `false`) |
| `description` | Passthroughs | Description of the custom ruleset. |
| `targetdir`   | Passthroughs | The directory where the final configuration should be persisted. If empty, a directory with a random name is created. The directory can contain up to 100 MB of files. |
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
    ref = "refs/heads/main"
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
[`gl-sast-report.json`](index.md#reports-json-format) produced by the analyzer.
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
This is currently supported by the `nodejs-scan` and `semgrep` analyzers only.

The `[[$analyzer.passthrough]]` section allows you to synthesize a custom configuration for an analyzer. You
can define up to 20 of these sections per analyzer. Passthroughs are composed into a _passthrough chain_
that evaluates into a complete configuration that replaces the predefined rules of the analyzer.

Passthroughs are evaluated in order. Passthroughs listed later in the chain have
a higher precedence and can overwrite or append to data yielded by previous
passthroughs (depending on the `mode`). This is useful for cases where you need
to use or modify an existing configuration.

The amount of data generated by a single passthrough is limited to 1 MB.

| Setting | Applies to | Description |
| ------- | ---------- | ----------- |
| `type` | All |  One of `file`, `raw`, `git` or `url`. |
| `target` | All | The target file to contain the data written by the passthrough evaluation. If empty, a random filename is used. |
| `mode` | All | If `overwrite`, the `target` file is overwritten. If `append`, new content is appended to the `target` file. The `git` type only supports `overwrite`. (Default: `overwrite`) |
| `ref` | `type = "git"` | Contains the name of the branch or the SHA to pull. When using a branch name, specify it in the form `refs/heads/<branch>`, not `refs/remotes/<remote_name>/<branch>`. |
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

### Disable predefined rules of SAST analyzers

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

### Override predefined rules of SAST analyzers

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

### Synthesize a custom configuration using a raw passthrough for `nodejs-scan`

With the following custom ruleset configuration, the predefined behavior
of the `nodejs-scan` analyzer is replaced with a custom configuration.

The syntax used for the `value` follows the [njsscan config format](https://github.com/ajinabraham/njsscan#configure-njsscan).

```toml
[nodejs-scan]
  description = "My custom ruleset for nodejs-scan"

  [[nodejs-scan.passthrough]]
    type  = "raw"
    value = '''
---
- nodejs-extensions:
  - .js
  
  template-extensions:
  - .new
  - .hbs
  - ''
  
  ignore-filenames:
  - skip.js
  
  ignore-paths:
  - __MACOSX
  - skip_dir
  - node_modules
  
  ignore-extensions:
  - .hbs
  
  ignore-rules:
  - regex_injection_dos
  - pug_jade_template
  - express_xss
'''
```

### Synthesize a custom configuration using a file passthrough for `semgrep`

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

### Synthesize a custom configuration using a passthrough chain for `semgrep`

With the following custom ruleset configuration, the predefined ruleset
of the `semgrep` analyzer is replaced with a custom ruleset produced by
evaluating a chain of four passthroughs. Each passthrough produces a file
that's written to the `/sgrules` directory within the container. A
`timeout` of 60 seconds is set in case any Git remotes are unresponsive.

Different passthrough types are demonstrated in this example:

- Two `git` passthroughs, the first pulling `refs/heads/test` from the
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
    ref = "refs/heads/test"

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
[Semgrep rule syntax](https://semgrep.dev/docs/writing-rules/rule-syntax/).

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
