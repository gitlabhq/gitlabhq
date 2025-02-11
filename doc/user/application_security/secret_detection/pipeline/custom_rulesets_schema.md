---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Custom rulesets schema
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can use [different kinds of ruleset customizations](../pipeline/_index.md#customize-analyzer-rulesets)
to customize the behavior of pipeline secret detection.

## Schema

Customization of pipeline secret detection rulesets must adhere to a strict schema. The following
sections describe each of the available options and the schema that applies to that section.

### The top-level section

The top-level section contains one or more _configuration sections_, defined as [TOML tables](https://toml.io/en/v1.0.0#table).

| Setting     | Description                                        |
|-------------|----------------------------------------------------|
| `[secrets]` | Declares a configuration section for the analyzer. |

Configuration example:

```toml
[secrets]
...
```

### The `[secrets]` configuration section

The `[secrets]` section lets you customize the behavior of the analyzer. Valid properties differ
based on the kind of configuration you're making.

| Setting               | Applies to       | Description                                                                                                                                                                                                                                                                              |
|-----------------------|------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `[[secrets.ruleset]]` | Predefined rules | Defines modifications to an existing rule.                                                                                                                                                                                                                                               |
| `interpolate`         | All              | If set to `true`, you can use `$VAR` in the configuration to evaluate environment variables. Use this feature with caution, so you don't leak secrets or tokens. (Default: `false`)                                                                                                      |
| `description`         | Passthroughs     | Description of the custom ruleset.                                                                                                                                                                                                                                                       |
| `targetdir`           | Passthroughs     | The directory where the final configuration should be persisted. If empty, a directory with a random name is created. The directory can contain up to 100 MB of files.                                                                                                                   |
| `validate`            | Passthroughs     | If set to `true`, the content of each passthrough is validated. The validation works for `yaml`, `xml`, `json` and `toml` content. The proper validator is identified based on the extension used in the `target` parameter of the `[[secrets.passthrough]]` section. (Default: `false`) |
| `timeout`             | Passthroughs     | The maximum time to spend to evaluate the passthrough chain, before timing out. The timeout cannot exceed 300 seconds. (Default: 60)                                                                                                                                                     |

#### `interpolate`

WARNING:
To reduce the risk of leaking secrets, use this feature with caution.

The example below shows a configuration that uses the `$GITURL` environment variable to access a
private repository. The variable contains a username and token
(for example `https://user:token@url`), so they're not explicitly stored in the configuration file.

```toml
[secrets]
  description = "My private remote ruleset"
  interpolate = true

  [[secrets.passthrough]]
    type  = "git"
    value = "$GITURL"
    ref = "main"
```

### The `[[secrets.ruleset]]` section

The `[[secrets.ruleset]]` section targets and modifies a single predefined rule. You can define
one to many of these sections for the analyzer.

| Setting                        | Description                                             |
|--------------------------------|---------------------------------------------------------|
| `disable`                      | Whether the rule should be disabled. (Default: `false`) |
| `[secrets.ruleset.identifier]` | Selects the predefined rule to be modified.             |
| `[secrets.ruleset.override]`   | Defines the overrides for the rule.                     |

Configuration example:

```toml
[secrets]
  [[secrets.ruleset]]
    disable = true
    ...
```

### The `[secrets.ruleset.identifier]` section

The `[secrets.ruleset.identifier]` section defines the identifiers of the predefined
rule that you wish to modify.

| Setting | Description |
| --------| ----------- |
| `type`  | The type of identifier used by the predefined rule. |
| `value` | The value of the identifier used by the predefined rule. |

To determine the correct values for `type` and `value`, view the
[`gl-secret-detection-report.json`](../pipeline/_index.md#output) produced by the analyzer.
You can download this file as a job artifact from the analyzer's CI job.

For example, the snippet below shows a finding from a `gitlab_personal_access_token` rule with one
identifier. The `type` and `value` keys in the JSON object correspond to the values you should
provide in this section.

```json
...
  "vulnerabilities": [
    {
      "id": "fccb407005c0fb58ad6cfcae01bea86093953ed1ae9f9623ecc3e4117675c91a",
      "category": "secret_detection",
      "name": "GitLab personal access token",
      "description": "GitLab personal access token has been found in commit 5c124166",
      ...
      "identifiers": [
        {
          "type": "gitleaks_rule_id",
          "name": "Gitleaks rule ID gitlab_personal_access_token",
          "value": "gitlab_personal_access_token"
        }
      ]
    }
    ...
  ]
...
```

Configuration example:

```toml
[secrets]
  [[secrets.ruleset]]
    [secrets.ruleset.identifier]
      type = "gitleaks_rule_id"
      value = "gitlab_personal_access_token"
    ...
```

### The `[secrets.ruleset.override]` section

The `[secrets.ruleset.override]` section allows you to override attributes of a predefined rule.

| Setting       | Description                                                                                         |
|---------------|-----------------------------------------------------------------------------------------------------|
| `description` | A detailed description of the issue.                                                                |
| `message`     | (Deprecated) A description of the issue.                                                            |
| `name`        | The name of the rule.                                                                               |
| `severity`    | The severity of the rule. Valid options are: `Critical`, `High`, `Medium`, `Low`, `Unknown`, `Info` |

NOTE:
Although `message` is still populated by the analyzers, it has been [deprecated](https://gitlab.com/gitlab-org/security-products/analyzers/report/-/blob/1d86d5f2e61dc38c775fb0490ee27a45eee4b8b3/vulnerability.go#L22)
and replaced by `name` and `description`.

Configuration example:

```toml
[secrets]
  [[secrets.ruleset]]
    [secrets.ruleset.override]
      severity = "Medium"
      name = "systemd machine-id"
    ...
```

### Custom rule format

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/511321) in GitLab 17.9.

When creating custom rules, you can use both [Gitleaks' standard rule format](https://github.com/gitleaks/gitleaks?tab=readme-ov-file#configuration) and additional GitLab-specific fields. The following settings are available for each rule:

| Setting | Description |
|---------|-------------|
| `title` | (Optional) A GitLab-specific field that sets a custom title for the rule. |
| `description` | A detailed description of what the rule detects. |
| `remediation` | (Optional) A GitLab-specific field that provides remediation guidance when the rule is triggered. |
| `regex` | The regular expression pattern used to detect secrets. |
| `keywords` | A list of keywords to pre-filter content before applying the regex. |
| `id` | A unique identifier for the rule. |

Example of a custom rule with all available fields:

```toml
[[rules]]
title = "API Key Detection Rule"
description = "Detects potential API keys in the codebase"
remediation = "Rotate the exposed API key and store it in a secure credential manager"
id = "custom_api_key"
keywords = ["apikey", "api_key"]
regex = '''api[_-]key[_-][a-zA-Z0-9]{16,}'''
```

When you create a custom rule that shares the same ID as a rule in the extended ruleset, your custom rule takes precedence. All properties of your custom rule replace the corresponding values from the extended rule.

Example of extending default rules with a custom rule:

```toml
title = "Extension of GitLab's default Gitleaks config"

[extend]
path = "/gitleaks.toml"

[[rules]]
title = "Custom API Key Rule"
description = "Detects custom API key format"
remediation = "Rotate the exposed API key"
id = "custom_api_123"
keywords = ["testing"]
regex = '''testing-key-[1-9]{3}'''
```

### The `[[secrets.passthrough]]` section

The `[[secrets.passthrough]]` section allows you to synthesize a custom configuration for an
analyzer.

You can define up to 20 of these sections per analyzer. Passthroughs are then composed into a
_passthrough chain_ that evaluates into a complete configuration that can be used to replace or
extend the predefined rules of the analyzer.

Passthroughs are evaluated in order. Passthroughs listed later in the chain have a higher precedence
and can overwrite or append to data yielded by previous passthroughs (depending on the `mode`). Use
passthroughs when you need to use or modify an existing configuration.

The size of the configuration generated by a single passthrough is limited to 10 MB.

| Setting     | Applies to     | Description                                                                                                                                                                   |
|-------------|----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `type`      | All            | One of `file`, `raw`, `git`, or `url`.                                                                                                                                        |
| `target`    | All            | The target file to contain the data written by the passthrough evaluation. If empty, a random filename is used.                                                               |
| `mode`      | All            | If `overwrite`, the `target` file is overwritten. If `append`, new content is appended to the `target` file. The `git` type only supports `overwrite`. (Default: `overwrite`) |
| `ref`       | `type = "git"` | Contains the name of the branch, tag, or the SHA to pull.                                                                                                                     |
| `subdir`    | `type = "git"` | Used to select a subdirectory of the Git repository as the configuration source.                                                                                              |
| `auth`      | `type = "git"` | Used to provide credentials to use when using a [configuration stored in a private Git repository](../pipeline/_index.md#with-a-private-remote-ruleset).                       |
| `value`     | All            | For the `file`, `url`, and `git` types, defines the location of the file or Git repository. For the `raw` type, contains the inline configuration.                            |
| `validator` | All            | Used to explicitly invoke validators (`xml`, `yaml`, `json`, `toml`) on the target file after the evaluation of a passthrough.                                                |

#### Passthrough types

| Type   | Description                                           |
|--------|-------------------------------------------------------|
| `file` | Use a file that is stored in the same Git repository. |
| `raw`  | Provide the ruleset configuration inline.             |
| `git`  | Pull the configuration from a remote Git repository.  |
| `url`  | Fetch the configuration using HTTP.                   |
