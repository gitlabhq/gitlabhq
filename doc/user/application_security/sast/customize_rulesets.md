---
stage: Secure
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Customize rulesets **(ULTIMATE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/235382) in GitLab 13.5.
> - [Added](https://gitlab.com/gitlab-org/gitlab/-/issues/339614) support for
>   passthrough chains. Expanded to include additional passthrough types of `file`, `git`, and `url` in GitLab 14.6.
> - [Added](https://gitlab.com/gitlab-org/gitlab/-/issues/235359) support for overriding rules in GitLab 14.8.

You can customize the default scanning rules provided by our SAST analyzers.
Ruleset customization supports the following that can be used
simultaneously:

- [Disabling predefined rules](#disable-predefined-analyzer-rules). Available for all analyzers.
- [Overriding predefined rules](#override-predefined-analyzer-rules). Available for all analyzers.
- Modifying the default behavior of a given analyzer by [synthesizing and passing a custom configuration](#synthesize-a-custom-configuration). Available for only `nodejs-scan`, `gosec`, and `semgrep`.

To customize the default scanning rules, create a file containing custom rules. These rules
are passed through to the analyzer's underlying scanner tools.

To create a custom ruleset:

1. Create a `.gitlab` directory at the root of your project, if one doesn't already exist.
1. Create a custom ruleset file named `sast-ruleset.toml` in the `.gitlab` directory.

## Disable predefined analyzer rules

To disable analyzer rules:

1. Set the `disabled` flag to `true` in the context of a `ruleset` section

1. In one or more `ruleset.identifier` sub sections, list the rules that you want disabled. Every `ruleset.identifier` section has:

- a `type` field, to name the predefined rule identifier that the targeted analyzer uses.
- a `value` field, to name the rule to be disabled.

### Example: Disable predefined rules of SAST analyzers

In the following example, the disabled rules are assigned to `eslint`
and `sobelow` by matching the `type` and `value` of identifiers:

```toml
[eslint]
  [[eslint.ruleset]]
    disable = true
    [eslint.ruleset.identifier]
      type = "eslint_rule_id"
      value = "security/detect-object-injection"

  [[eslint.ruleset]]
    disable = true
    [eslint.ruleset.identifier]
      type = "cwe"
      value = "185"

[sobelow]
  [[sobelow.ruleset]]
    disable = true
    [sobelow.ruleset.identifier]
      type = "sobelow_rule_id"
      value = "sql_injection"
```

Those vulnerabilities containing the provided type and value are now disabled, meaning
they won't be displayed in Merge Request nor the Vulnerability Report.

## Override predefined analyzer rules

To override analyzer rules:

1. In one or more `ruleset.identifier` subsections, list the rules that you want to override. Every `ruleset.identifier` section has:

   - a `type` field, to name the predefined rule identifier that the targeted analyzer uses.
   - a `value` field, to name the rule to be overridden.

1. In the `ruleset.override` context of a `ruleset` section,
   provide the keys to override. Any combination of keys can be
   overridden. Valid keys are:

   - description
   - message
   - name
   - severity (valid options are: Critical, High, Medium, Low, Unknown, Info)

### Example: Override predefined rules of SAST analyzers

Before adding a ruleset, we verify which vulnerability will be overwritten by viewing the [`gl-sast-report.json`](index.md#reports-json-format):

```json
"identifiers": [
        {
          "type": "gosec_rule_id",
          "name": "Gosec Rule ID G307",
          "value": "G307"
        },
        {
          "type": "CWE",
          "name": "CWE-703",
          "value": "703",
          "url": "https://cwe.mitre.org/data/definitions/703.html"
        }
      ]
```

In the following example, rules from `gosec` are matched by the `type`
and `value` of identifiers and then overridden:

```toml
[gosec]
  [[gosec.ruleset]]
    [gosec.ruleset.identifier]
        type = "CWE"
        value = "703"
    [gosec.ruleset.override]
      severity = "Critical"
```

If a vulnerability is found with a type `CWE` with a value of `703` then
the vulnerability severity is overwritten to `Critical`.

## Synthesize a custom configuration

To create a custom configuration, you can use passthrough chains.

A passthrough is a single step in a passthrough chain. The passthrough is evaluated
in a sequence to incrementally build a configuration. The configuration is then
passed to the target analyzer.

A configuration section for an analyzer has the following
parameters:

| Parameter     | Explanation |
| ------------- | ------ |
| `description` | Description about the analyzer configuration section. |
| `targetdir`   | The `targetdir` parameter defines the directory where the final configuration is located. If `targetdir` is empty, the analyzer uses a random directory. The maximum size of `targetdir` is 100MB. |
| `validate`    | If set to `true`, the target files for passthroughs (`raw`, `file` and `url`) are validated. The validation works for `yaml`, `xml`, `json` and `toml` files. The proper validator is identified based on the extension of the target file. By default, `validate` is set to `false`. |
| `interpolate` | If set to `true`, environment variable interpolation is enabled so that the configuration uses secrets/tokens. We advise using this feature with caution to not leak any secrets. By default, `interpolate` is set to `false`. |
| `timeout`     | The total `timeout` for the evaluation of a passthrough chain is set to 60 seconds. If `timeout` is not set, the default timeout is 60 seconds. The timeout cannot exceed 300 seconds. |

A configuration section can include one or more passthrough sections. The maximum number of passthrough sections is 20.
There are several types of passthroughs:

| Type   | Description |
| ------ | ------ |
| `file` | Use a file that is already available in the Git repository. |
| `raw`  | Provide the configuration inline. |
| `git`  | Pull the configuration from a remote Git repository. |
| `url`  | Fetch the analyzer configuration through HTTP. |

If multiple passthrough sections are defined in a passthrough chain, their
position in the chain defines the order in which they are evaluated.

- Passthroughs listed later in the chain sequence have a higher precedence.
- Passthroughs with a higher precedence overwrite (default) and append data
  yielded by previous passthroughs. This is useful for cases where you need to
  use or modify an existing configuration.

Configure a passthrough these parameters:

| Parameter     | Explanation |
| ------------ | ----------- |
| `type`       | One of `file`, `raw`, `git` or `url`. |
| `target`     | The target file that contains the data written by the passthrough evaluation. If no value is provided, a random target file is generated. |
| `mode`       | `overwrite`: if `target` exists, overwrites the file; `append`: append to file instead. The default is `overwrite`. |
| `ref`        | This option only applies to the `git` passthrough type and contains the name of the branch or the SHA to be used. |
| `subdir`     | This option only applies to the `git` passthrough type and can be used to only consider a certain subdirectory of the source Git repository. |
| `value`      | For the `file` `url` and `git` types, `value` defines the source location of the file/Git repository; for the `raw` type, `value` carries the raw content to be passed through. |
| `validator`  | Can be used to explicitly invoke validators (`xml`, `yaml`, `json`, `toml`) on the target files after the application of a passthrough. Per default, no validator is set. |

The amount of data generated by a single passthrough is limited to 1MB.

## Passthrough configuration examples

### Raw passthrough for nodejs-scan

Define a custom analyzer configuration. In this example, customized rules are
defined for the `nodejs-scan` scanner:

```toml
[nodejs-scan]
  description = 'custom ruleset for nodejs-scan'

  [[nodejs-scan.passthrough]]
    type  = "raw"
    value = '''
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

### File passthrough for Gosec

Provide the name of the file containing a custom analyzer configuration. In
this example, customized rules for the `gosec` scanner are contained in the
file `gosec-config.json`:

```toml
[gosec]
  description = 'custom ruleset for gosec'

  [[gosec.passthrough]]
    type  = "file"
    value = "gosec-config.json"
```

### Passthrough chain for Semgrep

In the below example, we generate a custom configuration under the `/sgrules`
target directory with a total `timeout` of 60 seconds.

Several passthrouh types generate a configuration for the target analyzer:

- Two `git` passthrough sections pull the head of branch
  `refs/remotes/origin/test` from the `myrules` Git repository, and revision
  `97f7686` from the `sast-rules` Git repository. From the `sast-rules` Git
  repository, only data from the `go` subdirectory is considered.
  - The `sast-rules` entry has a higher precedence because it appears later in
    the configuration.
  - If there is a filename collision between files in both repositories, files
    from the `sast` repository overwrite files from the `myrules` repository,
    as `sast-rules` has higher precedence.
- The `raw` entry creates a file named `insecure.yml` under `/sgrules`. The
  full path is `/sgrules/insecure.yml`.
- The `url` entry fetches a configuration made available through a URL and
  stores it in the `/sgrules/gosec.yml` file.

Afterwards, Semgrep is invoked with the final configuration located under
`/sgrules`.

```toml
[semgrep]
  description = 'semgrep custom rules configuration'
  targetdir = "/sgrules"
  timeout = 60

  [[semgrep.passthrough]]
    type  = "git"
    value = "https://gitlab.com/user/myrules.git"
    ref = "refs/remotes/origin/test"

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

### Interpolation

The code snippet below shows an example configuration that uses an environment
variable `$GITURL` to access a private repositories with a Git URL. The variable contains
a username and token in the `value` field (for example `https://user:token@url`).
It does not explicitly store credentials in the configuration file. To reduce the risk of leaking secrets through created paths and files, use this feature with caution.

```toml
[semgrep]
  description = 'semgrep custom rules configuration'
  targetdir = "/sgrules"
  interpolate = true

  [[semgrep.passthrough]]
    type  = "git"
    value = "$GITURL"
    ref = "refs/remotes/origin/main"
```

### Configure the append mode for passthroughs

To append data to previous passthroughs, use the `append` mode for the
passthrough types `file`, `url`, and `raw`.

Passthroughs in `override` mode overwrite files
created when preceding passthroughs in the chain find a naming
collision. If `mode` is set to `append`, a passthrough appends data to the
files created by its predecessors instead of overwriting.

In the below Semgrep configuration,`/sgrules/insecure.yml` assembles two passthroughs. The rules are:

- `insecure`
- `secret`

These rules add a search pattern to the analyzer and extends Semgrep capabilities.

For passthrough chains we recommend that you enable validation. To enable validation,
you can either:

- set `validate` to `true`

- set a passthrough `validator` to `xml`, `json`, `yaml`, or `toml`.

```toml
[semgrep]
  description = 'semgrep custom rules configuration'
  targetdir = "/sgrules"
  validate = true

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
    cwe: "...
  severity: "ERROR"
  languages:
  - "go"
"""

  [[semgrep.passthrough]]
    type  = "raw"
    mode  = "append"
    target = "insecure.yml"
    value = """
- id: "secret"
  patterns:
  - pattern-either:
    - pattern: "$MASK = \"...\""
  - metavariable-regex:
      metavariable: "$MASK"
      regex: "(password|pass|passwd|pwd|secret|token)"
  message: |
    Use of Hard-coded Password
    cwe: "..."
  severity: "ERROR"
  languages:
  - "go"
"""
```
